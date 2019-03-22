#
# Copyright 2016-2019 (c) Andrey Galkin
#

Puppet::Type.newtype(:cfsystem_secure_path) do
    desc "Helper for sudo secure_path limitation"

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
        desc "Named secure path"
        isnamevar
    end

    newproperty(:path, :array_matching => :all) do
        desc "Section name"
        isrequired
        
        validate do |value|
            value.is_a? String and !value.empty?
        end
    end
end
