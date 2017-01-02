#
# Copyright 2016-2017 (c) Andrey Galkin
#


# Please see README
class cfsystem::debian::cache(
    $acng_patterns = {},
) {
    # Required by stretch/xenial
    user { '_apt':
        ensure => present,
        home   => '/nonexistent',
        shell  => '/bin/false',
        gid    => 'nogroup',
    }

    if $::cfsystem::add_repo_cacher {
        $acng_patterns_def = {
            'P' => [],
            'V' => [
                '/download/geoip/database/.*\.dat\.gz'
            ],
            'S' => [],
            'SV' => [],
            'W' => [],
        }
        $acng_content = ($acng_patterns_def.map |$k, $v| {
            $va = ($v + pick_default($acng_patterns[$k], [])).join('|')

            if size($va) > 0 {
                "${k}filePatternEx: (${va})$"
            } else {
                undef
            }
        }.filter |$v| { $v != undef }) + [
            'PassThroughPattern: .*:443$'
        ]

        package { 'apt-cacher-ng': } ->
        service { 'apt-cacher-ng':
            ensure => running,
            enable => true,
        }

        file { '/etc/apt-cacher-ng/cfsystem.conf':
            content => $acng_content.join("\n"),
            notify  => Service['apt-cacher-ng'],
        }


        cfnetwork::describe_service{ 'apcng':
            server => 'tcp/3142' }
        cfnetwork::service_port{ "${cfsystem::service_face}:apcng:cfsystem": }
        case $cfsystem::service_face {
        'any', 'local': {}
        default: { cfnetwork::service_port{ 'local:apcng:cfsystem': } }
        }
        cfnetwork::client_port{ 'any:http:apcng': user=>['apt-cacher-ng', 'root', '_apt'] }
        cfnetwork::client_port{ 'any:https:apcng': user=>['apt-cacher-ng', 'root', '_apt'] }

        cfsystem_memory_weight { 'cfsystem::acng':
            ensure => present,
            weight => 1,
            min_mb => 64,
        }
    }

    $proxy = $::cfsystem::repo_proxy

    if $proxy and $proxy['port'] {
        $proxy_port = $proxy['port']
        $proxy_host = $proxy['host']
        cfnetwork::describe_service{ 'aptproxy':
            server => "tcp/${proxy_port}" }
        cfnetwork::client_port{ 'any:aptproxy:cfsystem':
            dst  => $proxy_host,
            user => ['root', '_apt'],
        }
    } else {
        cfnetwork::client_port{ 'any:http:cfsystem': user => ['root', '_apt'] }
        cfnetwork::client_port{ 'any:https:cfsystem': user => ['root', '_apt'] }
    }
}
