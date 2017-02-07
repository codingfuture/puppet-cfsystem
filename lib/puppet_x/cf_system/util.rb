#
# Copyright 2016-2017 (c) Andrey Galkin
#


require 'puppet/util/logging'
require 'puppet/util/diff'
require 'puppet/util/execution'
require 'fileutils'
require 'tempfile'
require 'securerandom'


module PuppetX::CfSystem::Util
    class << self
        include Puppet::Util::Logging
        Puppet::Util.logmethods(self, true)
    end
    
    BASE_PORT = 1025 unless defined? BASE_PORT
    NETSTAT = '/bin/netstat' unless defined? NETSTAT
    JAVA = '/usr/bin/java' unless defined? JAVA
    DPKG = '/usr/bin/dpkg' unless defined? DPKG    
    
    #---
    def self.cf_stable_cmp(a, b)
        if a.is_a? Hash and b.is_a? Hash
            a_keys = a.keys()
            b_keys = b.keys()
            
            c = [a_keys.size(), b_keys.size()].max
            
            c.times do |i|
                return -1 if i >= a_keys.size()
                return 1 if i >= b_keys.size()
                ak = a_keys[i]
                bk = b_keys[i]
                cmp = ak <=> bk
                return cmp if cmp != 0
                cmp = cf_stable_cmp(a[ak], b[bk])
                return cmp if cmp != 0
            end
            
            return 0
        elsif a.is_a? Hash and !b.is_a? Hash
            return -1
        elsif !a.is_a? Hash and b.is_a? Hash
            return 1
        elsif a.is_a? Array and b.is_a? Array
            c = [a.size(), b.size()].max
            
            c.times do |i|
                return -1 if i >= a.size()
                return 1 if i >= b.size()
                cmp = cf_stable_cmp(a[i], b[i])
                return cmp if cmp != 0
            end
            
            return 0
        elsif a.is_a? Array and !b.is_a? Array
            return -1
        elsif !a.is_a? Array and b.is_a? Array
            return 1
        else
            return a <=> b
        end
    end

    #---
    def self.cf_stable_sort(arg)
        if arg.is_a? Hash
            ret = {}
            arg.keys.sort.each do |k|
                ret[k] = cf_stable_sort(arg[k])
            end
        elsif arg.is_a? Array
            ret = arg.map do |v|
                cf_stable_sort(v)
            end
                
            ret.sort! do |a, b|
                cf_stable_cmp(a, b)
            end
        else
            ret = arg
        end
        
        #warning("In #{arg}")
        #warning("Out #{ret}")
        ret
    end

    #---
    def self.genPortCommon(ports, assoc_id, forced_port)
        forced_port = forced_port.to_i
        
        if forced_port > 0 and ports[assoc_id] != forced_port
            old_assoc_id = ports.key(forced_port)
            if not old_assoc_id.nil?
                ports.delete(old_assoc_id)
                warning(" > deassociated #{forced_port} from #{old_assoc_id} in favor of #{assoc_id}")
            end
            ports[assoc_id] = forced_port
        end
        
        return ports[assoc_id] if ports[assoc_id].to_i > 0
        
        next_port = BASE_PORT
        
        if not ports.empty?
            sorted_ports = ports.values.sort
            port_index = 0
            
            while sorted_ports.length > port_index
                if sorted_ports[port_index] < next_port
                    port_index += 1
                elsif sorted_ports[port_index] == next_port
                    next_port += 1
                else
                    break
                end
            end
        end
        
        ports[assoc_id] = next_port
        return next_port
    end
    

    #---
    def self.genSecretCommon(secrets, assoc_id, len, set)
        if not secrets.has_key? assoc_id
            if set.nil? or set.empty?
                if len < 4
                    fail("Requested secret length is too short #{len} for #{assoc_id}")
                end
                secrets[assoc_id] = SecureRandom.urlsafe_base64((len * 3 / 4).to_i)
            else
                secrets[assoc_id] = set
            end
        end
        
        return secrets[assoc_id]
    end
    
    #---
    def self.genKeyCommon(secrets, assoc_id, gen_opts, set)
        return secrets[assoc_id] if secrets.has_key? assoc_id
        fail("#{assoc_id} is missing from #{secrets}")
        
        key_type = gen_opts['type']
        key_bits = gen_opts['bits']
        
        tmp_dir = '/tmp/cfsystem'
        FileUtils.mkdir_p(tmp_dir)
        FileUtils.chmod(0700, tmp_dir)
        
        tmp_obj = Tempfile.new('id', tmp_dir)
        tmp_file = "#{tmp_obj.path}key"
        tmp_pub_file = "#{tmp_file}.pub"
        
        # Unfortunately, PuppetServer's JRuby is very limited on installed gems
        # it's safer and simpler to use official keygen
        Puppet::Util::Execution.execute([
            '/usr/bin/ssh-keygen',
            '-q',
            '-b', key_bits,
            '-t', key_type,
            '-P', '',
            '-f', tmp_file,
        ])

        key_info = gen_opts.dup
        key_info['private'] = File.read(tmp_file)
        key_info['public'] = File.read(tmp_pub_file).split(' ')[1]

        tmp_obj.close!
        FileUtils.rm_f tmp_file
        FileUtils.rm_f tmp_pub_file

        secrets[assoc_id] = key_info
        return key_info
    end
    
    #---
    def self.mutablePersistence(scope, section)
        catalog = scope.catalog
        
        if !catalog.respond_to? :cf_fact or !catalog.respond_to? :cf_mutable
            class << catalog
                attr_accessor :cf_fact
                attr_accessor :cf_mutable
            end
        end
        
        fact = scope.lookupvar('::facts').fetch('cf_persistent', {})

        if catalog.cf_fact.object_id != fact.object_id
            mutable = {}
            fact.each do |ik, iv|
                mutable[ik] = iv.dup
            end
            
            catalog.cf_mutable = mutable
            catalog.cf_fact = fact
        else
            mutable = catalog.cf_mutable
        end
        
        persist = catalog.cf_mutable
        persist[section] ||= {}
        persist[section]
    end
    
    #---
    def self.wait_sock(service_name, service_port, timeout=180, initial_wait=0, interval=1)
        sleep initial_wait if initial_wait > 0
        timeout = (timeout / interval).to_i
        
        for i in 1..timeout
            if service_port.is_a? String
                return true if File.exists? service_port
            else
                res = Puppet::Util::Execution.execute(
                    [NETSTAT, '-tln'],
                    {
                        :failonfail => false,
                    }
                )
                return true if res.include?(":#{service_port}")
            end
            
            
            warning("Waiting #{service_name} startup (#{i})!")
            sleep interval
        end
        
        fail("Failed to wait for #{service_name} startup")
    end
    
    #---
    def self.is_jvm_metaspace
        res = Puppet::Util::Execution.execute(
            [JAVA, '-XX:MaxMetaspaceSize=8m', '-version'],
            {
                :failonfail => false,
                :squelch => true,
                :uid => 'puppet',
                :gid => 'puppet',
            }
        )
        
        res.exitstatus == 0
    end
    
    #---
    def self.get_package_version(package)
        res = Puppet::Util::Execution.execute(
            [DPKG, '--status', package],
            {
                :uid => 'puppet',
                :gid => 'puppet',
            }
        )

        res.split("\n").each do |v|
            vs = v.split(': ')
            return vs[1] if vs[0] == 'Version'
        end

        fail("Unknown package version: #{package}")
    end
end
