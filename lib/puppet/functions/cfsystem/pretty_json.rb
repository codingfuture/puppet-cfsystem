#
# Copyright 2017 (c) Andrey Galkin
#


require 'json'

Puppet::Functions.create_function(:'cfsystem::pretty_json') do
    dispatch :cf_pretty_json do
        param 'Data', :arg
    end
    
    def cf_pretty_json(arg)
        JSON.pretty_generate(arg)
    end
end
