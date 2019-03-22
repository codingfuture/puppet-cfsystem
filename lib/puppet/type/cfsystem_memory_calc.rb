#
# Copyright 2016-2019 (c) Andrey Galkin
#

Puppet::Type.newtype(:cfsystem_memory_calc) do
    desc "Calculate memory scopes based on configured weights"
    
    autorequire(:cfsystem_flush_config) do
        ['begin']
    end
    autonotify(:cfsystem_flush_config) do
        ['commit']
    end    
    
    ensurable do
        defaultvalues
        defaultto :absent
    end

    newparam(:name) do
        desc "Must always be 'total'"
        isnamevar
        
        validate do |value|
            unless value == 'total'
                raise ArgumentError, "The only title allowed is 'total'"
            end
        end
    end
end
