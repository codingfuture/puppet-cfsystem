
# Done this way due to some weird behavior in tests also ignoring $LOAD_PATH
require File.expand_path( '../../../../puppet_x/cf_system', __FILE__ )

Puppet::Type.type(:cfsystem_info).provide(
    :cfprovider,
    :parent => PuppetX::CfSystem::ProviderBase
) do
    desc "Provider for cfsystem_info"
    
    
    def self.get_config_index
        'info'
    end
    
    def self.get_generator_version
        cf_system().makeVersion(__FILE__)
    end
    
    def self.on_config_change(newconf)
    end
    
    def self.instances
        debug('self.instances')
        instances = []
        type = get_config_index()
        config_type = cf_system().config.get_old(type)
                
        config_type.each do |k, v|
            instances << self.new({
                :name => k,
                :ensure => :exists,
                :info => v,
            })
        end
        
        debug('Instances:' + instances.to_s)
        instances
    end
    
    def flush
        debug('flush')
        ensure_val = @property_hash[:ensure]
            
        case ensure_val 
        when :absent
            write_config(@resource[:name], nil)
        when :present, :exists
            write_config(@resource[:name], @resource[:info])
        else
            warning(@resource)
            warning(@property_hash)
            raise Puppet::DevError, "Unknown 'ensure' = " + ensure_val.to_s
        end
    end    
end
