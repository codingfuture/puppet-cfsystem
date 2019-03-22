#
# Copyright 2018-2019 (c) Andrey Galkin
#

Puppet::Type.newtype(:cf_notify) do
    desc "notify resource type replacement with no refresh side effects"

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
        desc "Message name"
        isnamevar
    end

    newproperty(:message) do
        desc "Message itself"
        isrequired
        defaultto { @resource[:name] }
    end

    newproperty(:loglevel_state) do
        desc "Saved log level"
        isrequired
        defaultto { @resource[:loglevel] }
    end
end
