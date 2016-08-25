
class cfsystem::debian::aptconfig {
    class {'apt':
        proxy  => $::cfsystem::repo_proxy_cond,
        update => $::cfsystem::apt_update,
        purge  => $::cfsystem::apt_purge,
    }

    #---
    apt::source { 'debian':
        location => $::cfsystem::debian::apt_url,
        release  => $::cfsystem::debian::release,
        repos    => 'main contrib non-free',
        include  => { src        => false },
        pin      => $cfsystem::apt_pin,
    }
    apt::source { 'debian-updates':
        location => $::cfsystem::debian::apt_url,
        release  => "${::cfsystem::debian::release}-updates",
        repos    => 'main contrib non-free',
        include  => { src        => false },
        pin      => $cfsystem::apt_pin,
    }
    apt::source { 'debian-backports':
        location => $::cfsystem::debian::apt_url,
        release  => "${::cfsystem::debian::release}-backports",
        repos    => 'main contrib non-free',
        include  => { src        => false },
        pin      => $cfsystem::apt_backports_pin,
    }
    apt::source { 'debian-security':
        location => $::cfsystem::debian::security_apt_url,
        release  => "${::cfsystem::debian::release}/updates",
        repos    => 'main contrib non-free',
        include  => { src        => false },
        pin      => $cfsystem::apt_pin,
    }

    # Use for temporary mapping with new releases
    case $::cfsystem::debian::release {
        'stretch': {
            $puppet_release = 'jessie'
        }
        default: {
            $puppet_release = $::cfsystem::debian::release
        }
    }

    $puppet_key_id = '47B320EB4C7C375AA9DAE1A01054B7A24BD6EC30'
    $puppet_key_server = 'hkp://pgp.mit.edu:80'
    $http_proxy = "http://${cfsystem::repo_proxy_cond['host']}:${cfsystem::repo_proxy_cond['port']}"
    apt::source { 'puppetlabs':
        location => 'http://apt.puppetlabs.com',
        release  => $puppet_release,
        repos    => 'PC1',
        key      => {
            id      => $puppet_key_id,
            server  => $puppet_key_server,
            options => "http-proxy='${http_proxy}'",
        },
        pin      => $cfsystem::apt_pin + 1,
    } ->
    exec { 'apt-key update puppetlabs':
        unless  => "/usr/bin/apt-key list | \
            /bin/grep '${puppet_key_id}' | \
            /bin/grep -v expired",
        command => "/usr/bin/apt-key adv \
            --keyserver-options http-proxy='${http_proxy}' \
            --keyserver ${puppet_key_server} \
            --recv-keys ${puppet_key_id}",
    }
    
    apt::conf { 'local-thin':
        content => [
            'APT::Install-Recommends "0";',
            'APT::Install-Suggests "0";',
            'Acquire::Languages "none";'
        ].join("\n"),
    }
    
    package { 'puppetlabs-release': ensure => absent }
    package { 'puppetlabs-release-pc1': ensure => absent }
}