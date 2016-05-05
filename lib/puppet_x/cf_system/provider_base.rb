
require 'puppet/provider'
require 'puppet_x'

# Done this way due to some weird behavior in tests also ignoring $LOAD_PATH
require File.expand_path( '../../cf_system', __FILE__ )

module PuppetX::CfSystem

class ProviderBase < Puppet::Provider
    def self.cf_system
        PuppetX::CfSystem
    end
    
    def cf_system
        self.class.cf_system
    end
    
    def self.resource_type=(resource)
        super
        debug('resource_type=: ' + resource.to_s)
        mk_resource_methods
    end
    
    def self.instances
        debug('self.instances')
        instances = []
        type = get_config_index()
        config_type = cf_system().config.get_old(type)
                
        config_type.each do |k, v|
            params = {}
            v.each do |vk, vv|
                params[vk.to_sym] = vv
            end
            
            params[:name] = k
            params[:ensure] = :exists
            
            if check_exists(params)
                instances << self.new(params)
            end
        end
        
        debug('Instances:' + instances.to_s)
        instances
    end
    
    def self.prefetch(resources)
        debug('self.prefetch')
        instances().each do |prov|
            if resource = resources[prov.name]
                resource.provider = prov
            end
        end
    end
    
    def write_config(name, opts)
        type = self.class.get_config_index()
        debug("cfsystem: #{type} #{name} #{opts}")
        
        cf_system = self.cf_system()
        config = cf_system.config
        
        config.set_save_handler(type, self.class.get_generator_version()) do |new_conf|
            self.class.on_config_change(new_conf)
        end
        
        config_type = config.get_new(type)

        if not opts.nil?
            config_type[name] = opts
        else config_type.has_key?(name)
            config_type.delete(name)
        end

        debug(config_type)
    end
    
    def flush
        debug('flush')
        ensure_val = @property_hash[:ensure]
            
        case ensure_val 
        when :absent
            write_config(@resource[:name], nil)
        when :present, :exists
            properties = {}
            self.class.resource_type.validproperties.each do |property|
                next if property == :ensure
                properties[property] = @resource[property]
            end
            write_config(@resource[:name], properties)
        else
            warning(@resource)
            warning(@property_hash)
            raise Puppet::DevError, "Unknown 'ensure' = " + ensure_val.to_s
        end
    end
    
    def create
        debug('create')
        @property_hash[:ensure] = :present
        flush
    end

    def destroy
        debug('destroy')
        @property_hash[:ensure] = :absent
        flush
    end

    def exists?
        debug('exists?')
        
        if @property_hash[:ensure] = :exists
            flush
        end
        
        @property_hash[:ensure] != :absent
    end
    
    def self.check_exists(params)
        true
    end
    
    def self.get_config_index
        raise Puppet::DevError, 'Each provider must implement self.get_config_index'
    end
    
    def self.get_generator_version
        raise Puppet::DevError, 'Each provider must implement self.get_generator_version: cf_system().makeVersion(__FILE__)'
    end
    
    def self.on_config_change(newconf)
        raise Puppet::DevError, 'Each provider must implement self.on_config_change'
    end
end    

end