#
# Copyright 2016 (c) Andrey Galkin
#

# Make sure to reload on each run at server
load File.expand_path( '../../../../puppet_x/cf_system/util.rb', __FILE__ )

module Puppet::Parser::Functions
    newfunction(:cf_genpass,  :type => :rvalue) do |args|
        assoc_id, len, set = args
        
        secrets = PuppetX::CfSystem::Util.mutableFact(self, 'secrets') do |v|
            lookupvar('::facts').fetch('cf_persistent', {})[v] or {}
        end
        PuppetX::CfSystem::Util.genSecretCommon(secrets, assoc_id, len, set)
    end
end
