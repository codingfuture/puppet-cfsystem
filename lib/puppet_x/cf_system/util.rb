
require 'puppet/util/logging'
require 'puppet/util/diff'
require 'puppet/util/execution'
require 'fileutils'
require 'securerandom'


module PuppetX::CfSystem::Util
    class << self
        include Puppet::Util::Logging
        Puppet::Util.logmethods(self, true)
    end
    
    BASE_PORT = 1025
    
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
    def self.mutableFact(scope, fact_name, &block)
        catalog = scope.catalog
        
        if not catalog.respond_to? :cf_mutable_fact
            class << catalog
                attr_accessor :cf_mutable_fact
            end
            
            catalog.cf_mutable_fact = {}
        end
        
        mutable_fact = catalog.cf_mutable_fact
        
        if not mutable_fact.has_key? fact_name
            mutable_fact[fact_name] = block.call(fact_name).dup
        end
        
        mutable_fact[fact_name]
    end    
end