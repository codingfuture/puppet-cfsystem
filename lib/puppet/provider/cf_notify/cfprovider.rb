#
# Copyright 2018-2019 (c) Andrey Galkin
#


# Done this way due to some weird behavior in tests also ignoring $LOAD_PATH
require File.expand_path( '../../../../puppet_x/cf_system', __FILE__ )

Puppet::Type.type(:cf_notify).provide(
    :cfprovider,
    :parent => PuppetX::CfSystem::ProviderBase
) do
    desc "Provider for cf_notify"
    
    def self.get_generator_version
        cf_system().makeVersion(__FILE__)
    end

    def self.get_config_index
        '99_notices'
    end
    
    def self.check_exists(params)
        send(params[:loglevel_state], params[:message])
        true
    end

    def self.on_config_change(newconf)
        newconf.each { |k, v| check_exists v }
    end
end
