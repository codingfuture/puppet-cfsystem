#
# Copyright 2016-2019 (c) Andrey Galkin
#


# Done this way due to some weird behavior in tests also ignoring $LOAD_PATH
require File.expand_path( '../../../../puppet_x/cf_system', __FILE__ )

Puppet::Type.type(:cfsystem_secure_path).provide(
    :cfprovider,
    :parent => PuppetX::CfSystem::ProviderBase
) do
    desc "Provider for cfsystem_secure_path"
    
    
    def self.get_config_index
        'secure_path'
    end
    
    def self.get_generator_version
        cf_system().makeVersion(__FILE__)
    end
    
    def self.on_config_change(newconf)
        secpath = newconf.values.reduce([]) { |m, v| m + v[:path] }

        cf_system.atomicWrite(
            '/etc/sudoers.d/secure_path',
            "\nDefaults secure_path=\"#{secpath.join(':')}\"\n",
            {:mode => 0440}
        )
    end
end
