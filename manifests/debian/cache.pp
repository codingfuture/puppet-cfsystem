class cfsystem::debian::cache {
    if $::cfsystem::add_repo_cacher {
        package { 'apt-cacher-ng': }
        service { 'apt-cacher-ng': ensure => running }
        
        file_line { 'apcng_enable_ssl_connect':
            ensure => present,
            path => '/etc/apt-cacher-ng/acng.conf',
            line => 'PassThroughPattern: .*:443$',
            require => Package['apt-cacher-ng'],
            notify => Service['apt-cacher-ng'],
        }
        
        cfnetwork::describe_service{ 'apcng':
            server => 'tcp/3142' }
        cfnetwork::service_port{ "${cfsystem::service_face}:apcng:cfsystem": }
        case $cfsystem::service_face {
        'any', 'local': {}
        default: { cfnetwork::service_port{ 'local:apcng:cfsystem': } }
        }
        cfnetwork::client_port{ 'any:http:apcng': user=>'apt-cacher-ng' }
        cfnetwork::client_port{ 'any:https:apcng': user=>'apt-cacher-ng' }
    }
    
    $proxy = $::cfsystem::repo_proxy
    
    if $proxy and $proxy['port'] {
        $proxy_port = $proxy['port']
        $proxy_host = $proxy['host']
        cfnetwork::describe_service{ 'aptproxy':
            server => "tcp/${proxy_port}" }
        cfnetwork::client_port{ 'any:aptproxy:cfsystem':
            dst => $proxy_host,
            user => 'root',
        }
    } else {
        cfnetwork::client_port{ 'any:http:cfsystem': user=>'root' }
        cfnetwork::client_port{ 'any:https:cfsystem': user=>'root' }
    }
}