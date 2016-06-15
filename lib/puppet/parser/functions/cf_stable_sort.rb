
module Puppet::Parser::Functions
    newfunction(:cf_stable_sort,  :type => :rvalue, :arity => 1) do |args|
        arg = args[0]
        
        if arg.is_a? Hash
            ret = arg.keys.sort.map do |k|
                function_cf_stable_sort(arg[k])
            end
        elsif arg.is_a? Array
            ret = arg.map do |v|
                function_cf_stable_sort(v)
            end
            ret.sort!
        else
            ret = arg
        end
        
        ret
    end
end
