#
# Copyright 2016-2019 (c) Andrey Galkin
#

Puppet::Type.newtype(:cfsystem_memory_weight) do
    desc "Make cfsystem aware of reserved memory with abstract weight"

    autorequire(:cfsystem_flush_config) do
        ['begin']
    end
    autonotify(:cfsystem_memory_calc) do
        ['total']
    end
    
    ensurable do
        defaultvalues
        defaultto :absent
    end

    newparam(:name) do
        desc "Named memory weight"
        isnamevar
    end
    
    newproperty(:weight) do
        desc "Abstract memory weight to reserve"
        
        validate do |value|
            unless ((value.is_a? Integer and value > 0) or
                    (resource.value(:name).split('/').size > 1) or
                    (resource.value(:min_mb).is_a? Integer))
                raise ArgumentError, "%s is not a valid positive integer" % value
            end
        end
    end
    
    newproperty(:min_mb) do
        desc "Minimum size to reserve"
        
        validate do |value|
            unless value.nil? or (value.is_a? Integer and value >= 0)
                raise ArgumentError, "%s is not nil or a valid positive integer" % value
            end
        end
    end
    
    newproperty(:max_mb) do
        desc "Maximum size to reserve"
        
        validate do |value|
            unless value.nil? or (value.is_a? Integer and value >= 0)
                raise ArgumentError, "%s is not nil or a valid positive integer" % value
            end
        end
    end
end
