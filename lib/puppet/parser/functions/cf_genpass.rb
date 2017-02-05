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
        PuppetX::CfSystem::Util.genSecretCommon(secrets, assoc_id, len, set)
    end
end
