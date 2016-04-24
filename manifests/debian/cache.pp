class cfsystem::debian::cache {
    # Required by stretch/xenial
    user { '_apt':
        ensure => present,
        home => '/nonexistent',
        shell => '/bin/false',
        gid => 'nogroup',
    }
    
    if $::cfsystem::add_repo_cacher {
        package { 'apt-cacher-ng': }
        service { 'apt-cacher-ng': ensure => running }
        
        file_line { 'apcng_enable_ssl_connect':
            ensure  => present,
            path    => '/etc/apt-cacher-ng/acng.conf',
            line    => 'PassThroughPattern: .*:443$',
            require => Package['apt-cacher-ng'],
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
