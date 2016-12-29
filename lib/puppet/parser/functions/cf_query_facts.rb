#
# Copyright 2016 (c) Andrey Galkin
#


module Puppet::Parser::Functions
    newfunction(:cf_query_facts,  :type => :rvalue) do |args|
        Puppet::Parser::Functions.function(:query_facts)
        function_query_facts(args)
    end
end
