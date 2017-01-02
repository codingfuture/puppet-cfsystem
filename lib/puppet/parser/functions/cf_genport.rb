#
# Copyright 2016-2017 (c) Andrey Galkin
#


# Make sure to reload on each run at server
load File.expand_path( '../../../../puppet_x/cf_system/util.rb', __FILE__ )

module Puppet::Parser::Functions
    newfunction(:cf_genport,  :type => :rvalue) do |args|
        assoc_id, forced_port = args
        
        ports = PuppetX::CfSystem::Util.mutableFact(self, 'ports') do |v|
            lookupvar('::facts').fetch('cf_persistent', {})[v] or {}
        end
        PuppetX::CfSystem::Util.genPortCommon(ports, assoc_id, forced_port)
    end
end
