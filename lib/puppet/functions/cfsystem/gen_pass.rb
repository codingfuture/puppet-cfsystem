#
# Copyright 2016-2019 (c) Andrey Galkin
#

require File.expand_path( '../../../../puppet_x/cf_system/util.rb', __FILE__ )

Puppet::Functions.create_function(:'cfsystem::gen_pass') do
    dispatch :cf_gen_pass do
        param 'String[1]', :assoc_id
        param 'Integer[8,32]', :length
        # yes, double optional
        optional_param  'Optional[String[1]]', :forced_pass
    end
    
    def cf_gen_pass(assoc_id, len, set=nil)
        secrets = PuppetX::CfSystem::Util.mutablePersistence(self, 'secrets')
        value = PuppetX::CfSystem::Util.genSecretCommon(secrets, assoc_id, len, set)

        call_function(
            'ensure_resources',
            'cfsystem_persist',
            {
                "secrets:#{assoc_id}" => {
                    :section => 'secrets',
                    :key     => assoc_id,
                    :value   => value,
                    :secret  => true,
                }
            }
        )
        
        return value
    end
end

