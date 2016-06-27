
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
    end
    
    def self.commit
        debug('cfsystem::commit')
        self.config.save()
        self.config = nil
    end
    
    def self.atomicWrite(file, content, opts={})
        content = content.join("\n") + "\n" if content.is_a? Array
        
        if File.exists?(file) and (content == File.read(file))
            debug("Content matches for #{file}")
            return false
        end
        
        #---
        tmpfile = file + ".#{$$}"
        
        File.open(tmpfile, 'w+', opts.fetch(:mode, 0600) ) do |f|
            f.write(content)
        end
        
        # Show diff
        #---
        if File.exists?(file)
            notice("File[#{file}]/content:\n" + Puppet::Util::Diff.diff(file, tmpfile))
        else
            notice("File[#{file}]/content:\n" + content)
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
        
        unless cpu_weight.nil?
            section_ini['CPUAccounting'] = 'true'
            section_ini['CPUShares'] = (1024 * cpu_weight.to_i / 100).to_i
        end
        
        unless io_weight.nil?
            io_weight = (1000 * io_weight.to_i / 100).to_i
            section_ini['BlockIOAccounting'] = 'true'
            section_ini['BlockIOWeight'] = fitRange(1, 1000, io_weight)
        end
        
        unless mem_limit.nil?
            section_ini['MemoryAccounting'] = 'true'
            section_ini['MemoryLimit'] = "#{mem_limit}M"
                    
            if mem_lock
                mem_lock = mem_limit * 1024 * 1024
                section_ini['LimitMEMLOCK'] = "#{mem_lock}"
            end
        end        
    end
    
    def self.createSlice(options)
        slice_name = options[:slice_name]
        slice_file = "/etc/systemd/system/#{slice_name}.service"
        
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
        
        reload = atomicWriteIni(slice_file, content_ini, {:mode => 0644})
        
        # reload on demand
        #---
        if reload
            Puppet::Util::Execution.execute(['/bin/systemctl', 'daemon-reload'])
        end
        
        return reload
    end
    
    def self.createService(options)
        service_name = options[:service_name]
        user = options.fetch(:user, service_name)
        group = options.fetch(:group, user)
        
        service_file = "/etc/systemd/system/#{service_name}.service"
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
            'Type' => 'simple',
            'Restart' => 'always',
            'RestartSec' => 5,
            'User' => user,
            'Group' => group,
            'UMask' => '0027',
            'RuntimeDirectory' => service_name,
        }.merge service_ini)

        service_ini['EnvironmentFile'] = env_file unless content_env.empty?        
        
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
            Puppet::Util::Execution.execute(['/bin/systemctl', 'daemon-reload'])
        end
        
        return env_changed || reload
    end
    
    def self.maskService(service_name)
        service_file = "/etc/systemd/system/#{service_name}.service"
        
        if !File.exists?(service_file) or !File.symlink?(service_file)
            warning("> systemd masking #{service_name}")
            Puppet::Util::Execution.execute(['/bin/systemctl', 'stop', service_name])
            Puppet::Util::Execution.execute(['/bin/systemctl', 'mask', service_name])
        end
    end
end
