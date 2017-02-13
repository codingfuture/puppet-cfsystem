#
# Copyright 2016-2017 (c) Andrey Galkin
#

require File.expand_path( '../../../../puppet_x/cf_system/util.rb', __FILE__ )

Puppet::Functions.create_function(:'cfsystem::gen_port') do
    dispatch :cf_gen_port do
        param 'String[1]', :assoc_id
        # yes, double optional
        optional_param  'Optional[Cfnetwork::Port]', :forced_port
    end
    
    def cf_gen_port(assoc_id, set=nil)
        ports = PuppetX::CfSystem::Util.mutablePersistence(self, 'ports')
        value = PuppetX::CfSystem::Util.genPortCommon(ports, assoc_id, set)

        call_function(
            :ensure_resources,
            'cfsystem_persist',
            {
                "ports:#{assoc_id}" => {
                    :section => 'ports',
                    :key     => assoc_id,
                    :value   => value,
                }
            }
        )
        
        return value
    end
end

