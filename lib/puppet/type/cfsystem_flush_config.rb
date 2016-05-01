Puppet::Type.newtype(:cfsystem_flush_config) do
    desc "DO NOT USE DIRECTLY."

    ensurable do
        defaultvalues
        defaultto :absent
    end

    newparam(:name) do
        isnamevar
        
        validate do |value|
            unless ['begin', 'commit'].include? value
                raise ArgumentError, "The only title allowed is 'total'"
            end
        end
    end
end
