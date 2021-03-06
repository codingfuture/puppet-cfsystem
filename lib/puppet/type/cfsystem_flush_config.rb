#
# Copyright 2016-2019 (c) Andrey Galkin
#

Puppet::Type.newtype(:cfsystem_flush_config) do
    desc "DO NOT USE DIRECTLY."

    ensurable do
        defaultvalues
        defaultto :present
    end

    newparam(:name) do
        isnamevar
        
        validate do |value|
            unless ['begin', 'commit'].include? value
                raise ArgumentError, "Invalid title"
            end
        end
    end
end
