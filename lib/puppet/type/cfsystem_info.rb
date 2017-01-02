#
# Copyright 2016-2017 (c) Andrey Galkin
#

Puppet::Type.newtype(:cfsystem_info) do
    desc "Store arbitrary section info in cfsystem.json"

    autorequire(:cfsystem_flush_config) do
        ['begin']
    end
    
    ensurable do
        defaultvalues
        defaultto :absent
    end

    newparam(:name) do
        desc "Named memory weight"
        isnamevar
    end
    
    newproperty(:info) do
        desc "Arbitrary hash with section info"
        isrequired
        
        validate do |value|
            value.is_a? Hash
        end
    end
end
