#
# Copyright 2016 (c) Andrey Galkin
#

# Make sure to reload on each run at server
load File.expand_path( '../../../../puppet_x/cf_system/util.rb', __FILE__ )

module Puppet::Parser::Functions
    newfunction(:cf_stable_sort,  :type => :rvalue, :arity => 1) do |args|
        arg = args[0]
        ret = PuppetX::CfSystem::Util.cf_stable_sort(arg)
        #warning("In #{arg}")
        #warning("Out #{ret}")
        ret
    end
end
