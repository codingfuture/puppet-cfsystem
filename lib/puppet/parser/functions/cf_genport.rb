#
# Copyright 2016-2017 (c) Andrey Galkin
#


# Make sure to reload on each run at server
load File.expand_path( '../../../../puppet_x/cf_system/util.rb', __FILE__ )

module Puppet::Parser::Functions
    newfunction(:cf_genport,  :type => :rvalue) do |args|
        fail('Not enough arguments') if args.size < 2
        
        assoc_id, forced_port = args
        
        ports = PuppetX::CfSystem::Util.mutablePersistence(self, 'ports')
        PuppetX::CfSystem::Util.genPortCommon(ports, assoc_id, forced_port)
    end
end
