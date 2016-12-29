#
# Copyright 2016 (c) Andrey Galkin
#


# Done this way due to some weird behavior in tests also ignoring $LOAD_PATH
require File.expand_path( '../../../../puppet_x/cf_system', __FILE__ )

Puppet::Type.type(:cfsystem_memory_calc).provide(
    :cfprovider,
    :parent => PuppetX::CfSystem::ProviderBase
) do
    desc "Provider for cfsystem_flush_config"
   
    def self.instances
        [self.new({:name => 'total'})]
    end
    
    def flush
        debug('flush')
        PuppetX::CfSystem.calcMemorySections()
    end
end
