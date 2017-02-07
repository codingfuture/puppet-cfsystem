#
# Copyright 2016-2017 (c) Andrey Galkin
#

# Make sure to reload on each run at server
load File.expand_path( '../../../../puppet_x/cf_system/util.rb', __FILE__ )

module Puppet::Parser::Functions
    newfunction(:cf_genpass,  :type => :rvalue) do |args|
        fail('Not enough arguments') if args.size < 2
        
        assoc_id, len, set = args
        
        secrets = PuppetX::CfSystem::Util.mutablePersistence(self, 'secrets')
        value = PuppetX::CfSystem::Util.genSecretCommon(secrets, assoc_id, len, set)
        
        Puppet::Parser::Functions.function(:ensure_resource)
        function_ensure_resource([
            'cfsystem_persist',
            "secrets:#{assoc_id}",
            {
                :section => 'secrets',
                :key     => assoc_id,
                :value   => value,
                :secret  => true,
            }
        ])
        
        value
    end
end
