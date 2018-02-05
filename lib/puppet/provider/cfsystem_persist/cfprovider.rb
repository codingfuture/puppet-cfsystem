#
# Copyright 2016-2018 (c) Andrey Galkin
#


# Done this way due to some weird behavior in tests also ignoring $LOAD_PATH
require File.expand_path( '../../../../puppet_x/cf_system', __FILE__ )

Puppet::Type.type(:cfsystem_persist).provide(
    :cfprovider,
    :parent => PuppetX::CfSystem::ProviderBase
) do
    desc "Provider for cfsystem_persist"
    
    def self.get_generator_version
        cf_system().makeVersion(__FILE__)
    end
    
    def self.on_config_change(newconf)
    end
    
    def self.instances
        debug('self.instances')
        instances = []

        persistent = cf_system().config.get_persistent_all
                
        persistent.each do |section, subsection|
            subsection.each do |k, v|
                instances << self.new({
                    :name => "#{section}:#{k}",
                    :ensure => :present,
                    :section => section,
                    :key => k,
                    :value => v,
                })
            end
        end
        
        #debug('Instances:' + instances.to_s)
        instances
    end
    
    def flush
        debug('flush')
        ensure_val = @property_hash[:ensure] || @resource[:ensure]
            
        case ensure_val 
        when :absent
        when :present
            persistent = cf_system().config.get_persistent_all
            section = @resource[:section]
            key = @resource[:key]
            persistent[section] ||= {}
            persistent[section][key] = @resource[:value]
        else
            warning(@resource)
            warning(@property_hash)
            raise Puppet::DevError, "Unknown 'ensure' = " + ensure_val.to_s
        end
    end    
end
