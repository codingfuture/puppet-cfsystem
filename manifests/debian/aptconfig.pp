
class cfsystem::debian::aptconfig {
    class {'apt':
        proxy => $::cfsystem::repo_proxy,
    }

    #---
    apt::source { 'debian':
        location => $::cfsystem::debian::apt_url,
        release  => $::cfsystem::debian::release,
        repos    => 'main contrib non-free',
        include  => { src        => false },
    }
    apt::source { 'debian-updates':
        location => $::cfsystem::debian::apt_url,
        release  => "${::cfsystem::debian::release}-updates",
        repos    => 'main contrib non-free',
        include  => { src        => false },
    }
    apt::source { 'debian-backports':
        location => $::cfsystem::debian::apt_url,
        release  => "${::cfsystem::debian::release}-backports",
        repos    => 'main contrib non-free',
        include  => { src        => false },
    }
    apt::source { 'debian-security':
        location => $::cfsystem::debian::security_apt_url,
        release  => "${::cfsystem::debian::release}/updates",
        repos    => 'main contrib non-free',
        include  => { src        => false },
    }

    apt::source { 'puppetlabs':
        location => 'http://apt.puppetlabs.com',
        release  => $::cfsystem::debian::release,
        repos    => 'PC1',
        key      => {
            id     => '47B320EB4C7C375AA9DAE1A01054B7A24BD6EC30',
            server => 'pgp.mit.edu',
        },
    }
    
    apt::conf { 'local-thin':
        content => '
APT::Install-Recommends "0";
APT::Install-Suggests "0";
Acquire::Languages "none";
',
    }
    
    package { 'puppetlabs-release': ensure => absent }
    package { 'puppetlabs-release-pc1': ensure => absent }
}