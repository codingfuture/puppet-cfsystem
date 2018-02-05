#
# Copyright 2017 (c) Andrey Galkin
#

require File.expand_path( '../../../../puppet_x/cf_system/util.rb', __FILE__ )

Puppet::Functions.create_function(:'cfsystem::gen_key') do
    dispatch :cf_gen_key do
        param 'String[1]', :assoc_id
        param 'Cfsystem::Keygenopts', :gen_opts
        # yes, double optional
        optional_param  'Optional[Cfsystem::Keyinfo]', :forced_key
    end
    
    def cf_gen_key(assoc_id, gen_opts, forced_key=nil)
        keys = PuppetX::CfSystem::Util.mutablePersistence(self, 'keys')
        value = PuppetX::CfSystem::Util.genKeyCommon(keys, assoc_id, gen_opts, forced_key)

        call_function(
            'ensure_resources',
            'cfsystem_persist',
            {
                "keys:#{assoc_id}" => {
                    :section => 'keys',
                    :key     => assoc_id,
                    :value   => PuppetX::CfSystem::Util.cf_stable_sort(value),
                    :secret  => true,
                }
            }
        )
        
        return value
    end
end
