#
# Copyright 2016-2017 (c) Andrey Galkin
#


module Puppet::Parser::Functions
    newfunction(:cf_query_resources,  :type => :rvalue) do |args|
        Puppet::Parser::Functions.function(:query_resources)
        function_query_resources(args)
    end
end
