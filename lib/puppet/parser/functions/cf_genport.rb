#
# Copyright 2016-2017 (c) Andrey Galkin
#


# Make sure to reload on each run at server
load File.expand_path( '../../../../puppet_x/cf_system/util.rb', __FILE__ )

module Puppet::Parser::Functions
    newfunction(:cf_genport,  :type => :rvalue) do |args|
        fail('Not enough arguments') if args.size < 1
        
        assoc_id, forced_port = args
        
        ports = PuppetX::CfSystem::Util.mutablePersistence(self, 'ports')
        value = PuppetX::CfSystem::Util.genPortCommon(ports, assoc_id, forced_port)

        Puppet::Parser::Functions.function(:ensure_resource)
        function_ensure_resource([
            'cfsystem_persist',
            "ports:#{assoc_id}",
            {
                :section => 'ports',
                :key     => assoc_id,
                :value   => value,
            }
        ])

        value
    end
end
