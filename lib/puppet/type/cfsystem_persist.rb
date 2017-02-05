#
# Copyright 2016-2017 (c) Andrey Galkin
#

Puppet::Type.newtype(:cfsystem_persist) do
    desc "Store arbitrary persistent data in cfsystem.json"

    autorequire(:cfsystem_flush_config) do
        ['begin']
    end
    autonotify(:cfsystem_flush_config) do
        ['commit']
    end    

    ensurable do
        defaultvalues
        defaultto :present
    end

    newparam(:name) do
        desc "Named memory weight"
        isnamevar
    end

    newproperty(:section) do
        desc "Section name"
        isrequired
        
        validate do |value|
            value.is_a? String and !value.empty?
        end
    end
    
    newproperty(:key) do
        desc "Key name"
        isrequired
        
        validate do |value|
            value.is_a? String and !value.empty?
        end
    end    
    
    newproperty(:value) do
        desc "Arbitrary hash with section info"
        isrequired
        
        validate do |value|
            value.is_a? Hash
        end
    end
end
