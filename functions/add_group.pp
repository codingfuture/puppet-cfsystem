#
# Copyright 2018-2019 (c) Andrey Galkin
#

function cfsystem::add_group(String[1] $user, String[1] $group) >> Any {
    $name = "add_${user}_to_${group}"

    exec { $name:
        command => "/usr/sbin/adduser ${user} ${group}",
        unless  => "/usr/bin/id -Gnz ${user} | /bin/grep -zq '^${group}$'",
        require => Group[$group],
    }

    Exec[$name]
}
