
require 'puppet/util/logging'
require 'puppet_x'
require 'puppet/util/diff'
require 'fileutils'
require 'securerandom'

# Done this way due to some weird behavior in tests also ignoring $LOAD_PATH
require File.expand_path( '../cf_system/config', __FILE__ )

module PuppetX::CfSystem
    CFSYSTEM_CONFIG = '/etc/cfsystem.json'
    
    class << self
        attr_accessor :config
        attr_accessor :memory_distribution
        
        include Puppet::Util::Logging
        Puppet::Util.logmethods(self, true)
    end
    
    def self.makeVersion(file)
        Digest::MD5.hexdigest(File.read(file))
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
        
        newconf.each do |k, v|
            weight = v[:weight]
            min_mb = v[:min_mb]
            total_weight += weight
            
            if not min_mb.nil?
                min_ram += min_mb
                min_weight += weight
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
        
        newconf.each do |k, v|
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
        newconf.each do |k, v|
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
    
    BASE_PORT = 1025
    
    def self.genPort(assoc_id)
        ports = self.config.get_persistent('ports')
        
        return ports[assoc_id] if ports.has_key? assoc_id
        
        if ports.empty?
            next_port = BASE_PORT
        else
            next_port = ports.values.max() + 1
        end
        
        ports[assoc_id] = next_port
        return next_port
    end
    
    def self.genSecret(assoc_id, len=32)
        secrets = self.config.get_persistent('secrets')
        
        if not secrets.has_key? assoc_id
            secrets[assoc_id] = SecureRandom.base64(len)
        end
        
        return secrets[assoc_id]
    end
end
