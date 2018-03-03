#
# Copyright 2016-2018 (c) Andrey Galkin
#


require 'puppet/util/logging'
require 'puppet_x'
require 'puppet/util/diff'
require 'puppet/util/execution'
require 'fileutils'
require 'securerandom'

# Done this way due to some weird behavior in tests also ignoring $LOAD_PATH
require File.expand_path( '../cf_system/config', __FILE__ )

module PuppetX::CfSystem
    CFSYSTEM_CONFIG = '/etc/cfsystem.json'
    CUSTOM_BIN_DIR = '/opt/codingfuture/bin'
    SYSTEMD_DIR = '/etc/systemd/system'
    SYSTEMD_CTL = '/bin/systemctl'
    SUDO = '/usr/bin/sudo'
    WAIT_SOCKET_BIN = "#{CUSTOM_BIN_DIR}/cf_wait_socket"
    
    
    #---
    BASE_DIR = File.expand_path('../', __FILE__)
    require "#{BASE_DIR}/cf_system/provider_base"
    require "#{BASE_DIR}/cf_system/util"
    
    class << self
        attr_accessor :config
        attr_accessor :memory_distribution
        
        include Puppet::Util::Logging
        Puppet::Util.logmethods(self, true)
    end
    
    def self.makeVersion(file)
        if file.is_a? Array
            content = []
            file.each do |f|
                content << File.read(f)
            end
            content = content.join()
        else
            content = File.read(file)
        end
        
        Digest::MD5.hexdigest(content)
    end
    
    def self.begin
        debug('cfsystem::begin')
        self.config = Config.new(CFSYSTEM_CONFIG)
        File.exists?(CFSYSTEM_CONFIG)
    end
    
    def self.commit
        debug('cfsystem::commit')
        self.config.save()
        self.config = nil
        self.post_commit()
    end
    
    def self.post_commit
        res = Puppet::Util::Execution.execute(
            ['/opt/codingfuture/bin/cf_kernel_version_check'],
            {
                :failonfail => false,
                :combine => true,
            }
        )
        warning(res) if res.exitstatus != 0
    end
    
    def self.atomicWrite(file, content, opts={})
        content = content.join("\n") + "\n" if content.is_a? Array
        
        if File.exists?(file) and (content == File.read(file))
            debug("Content matches for #{file}")
            return false
        end
        
        return true if opts[:dry_run]
        
        #---
        tmpfile = file + ".#{$$}"
        
        File.open(tmpfile, 'w+', opts.fetch(:mode, 0600) ) do |f|
            f.write(content)
        end
        
        # Show diff
        #---
        if opts.fetch(:show_diff, true)
            if File.exists?(file)
                diff = Puppet::Util::Diff.diff(file, tmpfile)
                opts.fetch(:mask_diff, []).each do |v|
                    diff.gsub!(v, '<secret>')
                end
                notice("File[#{file}]/content:\n" + diff)
            else
                notice("File[#{file}]/content:\n" + content)
            end
        else
            notice("File[#{file}] hidden content change")
        end

        # Atomically move config file to its location
        #---
        user = opts.fetch(:user, 'root')
        group = opts.fetch(:group, user)
        FileUtils.chown(user, group, tmpfile)
        File.rename(tmpfile, file)
        debug("Writed a new #{file}")
        
        return true
    end
    
    def self.atomicWriteIni(file, settings, opts={})
        content = []
        settings.each do |section, subsettings|
            content << "[#{section}]"
            subsettings.each do |k, v|
                if v.is_a? Array
                    v.each do |ve|
                        content << "#{k}=#{ve}"
                    end
                else
                    content << "#{k}=#{v}"
                end
            end
            content << ''
        end
        
        content = content.join("\n")
        
        self.atomicWrite(file, content, opts)
    end
    
    def self.atomicWriteEnv(file, settings, opts={})
        content = []
        settings.each do |k, v|
            if v.is_a? Array
                v = v.join(' ')
            end
            
            content << "#{k}=\"#{v}\""
        end
        
        content << ''
        
        content = content.join("\n")
        
        self.atomicWrite(file, content, opts)
    end
    
    def self.calcMemorySections()
        debug('Calculating RAM sections')
        
        total_ram = Facter['memory'].value['system']['total_bytes']
        total_ram = total_ram / 1024 / 1024
        debug("Total RAM: #{total_ram}MB")
        
        newconf = self.config.get_new('memory_weight')
        
        # Calc minimum allocations and totals
        #---
        min_ram = 0
        total_weight = 0
        min_weight = 0
        merged_conf = {}
        
        newconf.each do |k, v|
            weight = v[:weight]
            min_mb = v[:min_mb]
            total_weight += weight
            
            if not min_mb.nil?
                min_ram += min_mb
                min_weight += weight
            end
            
            # Support sub-section definition
            k = k.split('/')[0]
            
            if merged_conf.has_key? k
                mv = merged_conf[k]
                mv[:weight] += weight
                
                min_mb = ((mv[:min_mb] || 0) + (min_mb || 0))
                max_mb = ((mv[:max_mb] || 0) + (v[:max_mb] || 0))
                mv[:min_mb] = min_mb if min_mb > 0
                mv[:max_mb] = max_mb if max_mb > 0
            else
                merged_conf[k] = v.clone
            end
        end
        
        if total_ram < min_ram
            warning('Memory sections: ' + newconf.to_s )
            raise ArgumentError, "Minimal ram required #{min_ram} is more than available #{total_ram}"
        end
        
        # Pass #1 whole memory distribution
        #---
        avail_ram = total_ram - min_ram
        total_min_ratio = (1 - min_ram.to_f / total_ram)
        alloc_ram = 0
        mem_distrib = {}
        
        merged_conf.each do |k, v|
            min_mb = v[:min_mb]
            min_mb = 0 if min_mb.nil?
            max_mb = v[:max_mb]
            weight = v[:weight] 
            
            calc_mem = (total_ram * weight * total_min_ratio / total_weight).to_i
            calc_mem += min_mb

            # Well, it's not completely fair situation
            if not max_mb.nil? and calc_mem > max_mb
                calc_mem = max_mb
            end
                
            alloc_ram += calc_mem
            mem_distrib[k] = calc_mem
        end
        
        # Pass #2 unallocated memory distribution
        #---
        unalloc_ram = total_ram - alloc_ram
        merged_conf.each do |k, v|
            next if not v[:max_mb].nil?
            
            weight = v[:weight] 
            
            calc_mem = (unalloc_ram * weight / total_weight).to_i
            alloc_ram += calc_mem
            mem_distrib[k] += calc_mem
        end
        
        #---
        self.memory_distribution = mem_distrib
        notice('Memory distribution result: ' + mem_distrib.to_s )
    end
    
    def self.getMemory(name)
        self.memory_distribution[name]
    end
    
    def self.genPort(assoc_id, forced_port=nil)
        ports = self.config.get_persistent('ports')
        PuppetX::CfSystem::Util.genPortCommon(ports, assoc_id, forced_port)
    end
        
    def self.genSecret(assoc_id, len=24, set=nil)
        secrets = self.config.get_persistent('secrets')
        PuppetX::CfSystem::Util.genSecretCommon(secrets, assoc_id, len, set)
    end
        
   
    def self.fitRange(min, max, val=nil)
        val = max if val.nil?
        return [min, [max, val].min].max
    end
    
    def self.roundTo(to, val)
        return (((val + to) / to).to_i * to).to_i
    end

    def self.createLimitsCommon(section_ini, options)
        cpu_weight = options.fetch(:cpu_weight, nil)
        io_weight = options.fetch(:io_weight, nil)
        mem_limit = options.fetch(:mem_limit, nil)
        mem_lock = options.fetch(:mem_lock, false)
        cgroups_v2 = false
        
        mem_limit = "#{mem_limit}M" if mem_limit.is_a? Integer
        
        if cgroups_v2
            unless cpu_weight.nil?
                section_ini['CPUAccounting'] = 'true'
                cpu_shares = (10000 * cpu_weight.to_i / 100).to_i
                section_ini['CPUWeight'] = fitRange(1, 10000, cpu_shares)
            end
            
            unless io_weight.nil?
                io_weight = (10000 * io_weight.to_i / 100).to_i
                section_ini['IOAccounting'] = 'true'
                section_ini['IOWeight'] = fitRange(1, 10000, io_weight)
            end
            
            unless mem_limit.nil?
                section_ini['MemoryAccounting'] = 'true'
                section_ini['MemoryMax'] = mem_limit
                        
                if mem_lock
                    section_ini['LimitMEMLOCK'] = "infinity"
                end
            end
        else
            unless cpu_weight.nil?
                section_ini['CPUAccounting'] = 'true'
                cpu_shares = (1024 * cpu_weight.to_i / 100).to_i
                section_ini['CPUShares'] = fitRange(2, 262144, cpu_shares)
            end
            
            unless io_weight.nil?
                io_weight = (500 * io_weight.to_i / 100).to_i
                section_ini['BlockIOAccounting'] = 'true'
                section_ini['BlockIOWeight'] = fitRange(10, 1000, io_weight)
            end
            
            unless mem_limit.nil?
                section_ini['MemoryAccounting'] = 'true'
                section_ini['MemoryLimit'] = mem_limit
                        
                if mem_lock
                    section_ini['LimitMEMLOCK'] = "infinity"
                end
            end
        end
    end
    
    def self.createSlice(options)
        slice_name = options[:slice_name]
        slice_file = "#{SYSTEMD_DIR}/#{slice_name}.slice"
        
        content_ini = options.fetch(:content_ini, {})
        
        # Unit
        #---
        content_ini['Unit'] = {} unless content_ini.has_key? 'Unit'
        unit_ini = content_ini['Unit']
        unit_ini['Description'] ||= slice_name
        unit_ini['DefaultDependencies'] ||= 'no'
        unit_ini['Before'] ||= 'slices.target'

        # Service
        #---
        content_ini['Slice'] = {} unless content_ini.has_key? 'Slice'
        slice_ini = content_ini['Slice']
        
        self.createLimitsCommon(slice_ini, options)
        
        reload = atomicWriteIni(slice_file, content_ini,
                                {:mode => 0644,
                                 :dry_run => options[:dry_run]})
        
        # reload on demand
        #---
        if reload
            Puppet::Util::Execution.execute([SYSTEMD_CTL, 'daemon-reload'])
        end
        
        return reload
    end
    
    def self.createService(options)
        service_name = options[:service_name]
        user = options.fetch(:user, service_name)
        group = options.fetch(:group, user)
        
        service_file = "#{SYSTEMD_DIR}/#{service_name}.service"
        env_file = "/etc/default/#{service_name}.conf"
        
        content_ini = options[:content_ini].clone
        content_env = options.fetch(:content_env, {}).clone
        
        # Unit
        #---
        content_ini['Unit'] = {} unless content_ini.has_key? 'Unit'
        unit_ini = content_ini['Unit']
        unit_ini['Description'] ||= service_name
        unit_ini['After'] ||= 'syslog.target network.target'
        
        # Install
        #---
        content_ini['Install'] ||= {
            'WantedBy' => 'multi-user.target',
        }

        # Service
        #---
        service_ini = content_ini['Service']
        service_ini.replace({
            'SyslogIdentifier' => service_name,
            'Type' => 'simple',
            'Restart' => 'always',
            'RestartSec' => 5,
            'User' => user,
            'Group' => group,
            'UMask' => '0027',
            'RuntimeDirectory' => service_name,
        }.merge service_ini)

        unless content_env.empty?
            if !service_ini['EnvironmentFile']
                service_ini['EnvironmentFile'] = env_file
            elsif service_ini['EnvironmentFile'].is_a? Array
                service_ini['EnvironmentFile'] << env_file
            else
                service_ini['EnvironmentFile'] = [
                    service_ini['EnvironmentFile'],
                    env_file,
                ]
            end
        end
        
        self.createLimitsCommon(service_ini, options)
        
        # Write configs
        #---
        if content_env.empty?
            FileUtils.rm_f(env_file)
        else
            env_changed = atomicWriteEnv(env_file, content_env, {:mode => 0644})
        end
        
        reload = atomicWriteIni(service_file, content_ini, {:mode => 0644})
        
        # reload on demand
        #---
        if reload
            Puppet::Util::Execution.execute([SYSTEMD_CTL, 'daemon-reload'])
        end
        
        # Make sure it's enabled
        Puppet::Util::Execution.execute([SYSTEMD_CTL, 'enable', service_name, '--no-reload'])
        
        return env_changed || reload
    end
    
    def self.maskService(service_name)
        service_file = "#{SYSTEMD_DIR}/#{service_name}.service"
        
        if !File.exists?(service_file) or !File.symlink?(service_file)
            warning("> systemd masking #{service_name}")
            Puppet::Util::Execution.execute([SYSTEMD_CTL, 'stop', service_name])
            Puppet::Util::Execution.execute([SYSTEMD_CTL, 'mask', service_name])
        end
    end
    
    def self.cleanupSystemD(prefix, new_files, ext='service')
        old_files = Dir.glob("#{SYSTEMD_DIR}/#{prefix}*.#{ext}").
                            map { |v| File.basename(v, ".#{ext}") }
        old_files -= new_files
        old_files.each do |s|
            file = "#{s}.#{ext}"
            
            if ext == 'service'
                begin
                    warning("Stopping old systemd file: #{file}")
                    Puppet::Util::Execution.execute([SYSTEMD_CTL, 'stop', file])
                rescue => e
                    err("Fail on stop: #{e}")
                end
            end
            
            warning("Removing old systemd file: #{file}")
            FileUtils.rm_f "#{SYSTEMD_DIR}/#{file}"
        end
        
        if old_files.size
            Puppet::Util::Execution.execute([SYSTEMD_CTL, 'daemon-reload'])
        end
    end
end
