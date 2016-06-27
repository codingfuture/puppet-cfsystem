
module Puppet::Parser::Functions
    newfunction(:cf_query_nodes,  :type => :rvalue) do |args|
        Puppet::Parser::Functions.function(:query_nodes)
        function_query_nodes(args)
    end
end
