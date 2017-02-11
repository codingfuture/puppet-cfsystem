#
# Copyright 2016-2017 (c) Andrey Galkin
#

require File.expand_path( '../../../../puppet_x/cf_system/util.rb', __FILE__ )

Puppet::Functions.create_function(:'cfsystem::stable_sort') do
    dispatch :cf_stable_sort do
        param 'Data', :arg
    end
    
    def cf_stable_sort(arg)
        PuppetX::CfSystem::Util.cf_stable_sort(arg)
    end
end
