#
# Copyright 2017 (c) Andrey Galkin
#


# Make sure to reload on each run at server
load File.expand_path( '../../../../puppet_x/cf_system/util.rb', __FILE__ )

module Puppet::Parser::Functions
    newfunction(:cf_genkey,  :type => :rvalue) do |args|
        fail('Not enough arguments') if args.size < 2
        
        assoc_id, gen_opts, forced_key = args
        
        keys = PuppetX::CfSystem::Util.mutablePersistence(self, 'keys')
        value = PuppetX::CfSystem::Util.genKeyCommon(keys, assoc_id, gen_opts, forced_key)

        # TODO: YES, it's insecure as the private key gets stored in catalog
        # in clear text. Need some sort of host-specific encryption.
        Puppet::Parser::Functions.function(:ensure_resource)
        function_ensure_resource([
            'cfsystem_persist',
            "keys:#{assoc_id}",
            {
                :key    => assoc_id,
                :value  => value,
                :secret => true,
            }
        ])
        
        value
    end
end
