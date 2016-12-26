
# Please see README
define cfsystem::debian::aptkey(
    $id,
    $extra_opts = {}
){
    create_resources(
        'apt::key',
        {
            "cfsystem_${title}" => {
                id      => $id,
                server  => $cfsystem::key_server,
                options => "http-proxy=${cfsystem::http_proxy}",
            }
        },
        $extra_opts
    )

    $cf_apt_key_updater = $cfsystem::custombin::cf_apt_key_updater
    exec { "cf_apt_key_updater ${title}":
        command => '/bin/true',
        unless  => "${cf_apt_key_updater} ${id} puppet",
        require => File[$cf_apt_key_updater],
    }
}
