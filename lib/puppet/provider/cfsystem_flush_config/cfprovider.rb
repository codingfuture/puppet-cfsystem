
# Done this way due to some weird behavior in tests also ignoring $LOAD_PATH
require File.expand_path( '../../../../puppet_x/cf_system/provider_base', __FILE__ )

Puppet::Type.type(:cfsystem_flush_config).provide(
    :cfprovider,
    :parent => PuppetX::CfSystem::ProviderBase
) do
    desc "Provider for cfsystem_flush_config"
    
    def self.instances
        cf_system().begin()
        [
            self.new({
                :name => 'begin',
                :ensure => :present,
            }),
            self.new({
                :name => 'commit',
                :ensure => :present,
            }),
        ]
    end
    
    def flush
        debug('flush')
        name = @resource[:name]
        
        if name == 'begin'
            #cf_system().begin()
        elsif name == 'commit'
            cf_system().commit()
        else
            raise Puppet::DevError, "Unknown cfsystem_flush_config" + name.to_s
        end
    end
end
