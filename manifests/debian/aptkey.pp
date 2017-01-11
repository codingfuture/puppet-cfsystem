#
# Copyright 2016-2017 (c) Andrey Galkin
#


# Please see README
define cfsystem::debian::aptkey(
    $id,
    $extra_opts = {}
){
    $key_options = empty($cfsystem::http_proxy) ? {
        false   => "http-proxy=${cfsystem::http_proxy}",
        default => ''
    }

    ensure_packages(['dirmngr'])
    create_resources(
        'apt::key',
        {
            "cfsystem_${title}" => {
                id      => $id,
                server  => $cfsystem::key_server,
                options => $key_options,
                require => Package['dirmngr'],
            }
        },
        $extra_opts
    )

    $cf_apt_key_updater = $cfsystem::custombin::cf_apt_key_updater
    exec { "cf_apt_key_updater ${title}":
        command => '/bin/true',
        unless  => "${cf_apt_key_updater} ${id} puppet",
        require => [
            File[$cf_apt_key_updater],
            Package['dirmngr'],
        ]
    }
}
