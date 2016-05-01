
# Done this way due to some weird behavior in tests also ignoring $LOAD_PATH
require File.expand_path( '../../../../puppet_x/cfsystem/providerbase', __FILE__ )

Puppet::Type.type(:cfsystem_memory_weight).provide(
    :cfprovider,
    :parent => PuppetX::CfSystem::ProviderBase
) do
    desc "Provider for cfsystem_memory_weight"
    
    
    def self.get_config_index
        'memory_weight'
    end
    
    def self.on_config_change(newconf)
    end
end
