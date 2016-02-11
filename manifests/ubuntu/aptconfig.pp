
class cfsystem::ubuntu::aptconfig {
    class {'apt':
        proxy => $::cfsystem::repo_proxy,
    }

    #---
    apt::source { 'ubuntu':
        location => $::cfsystem::ubuntu::apt_url,
        release => $::cfsystem::ubuntu::release,
        repos => 'main restricted universe multiverse',
        include => { src => false },
    }
    apt::source { 'ubuntu-updates':
        location => $::cfsystem::ubuntu::apt_url,
        release => "${::cfsystem::ubuntu::release}-updates",
        repos => 'main restricted universe multiverse',
        include => { src => false },
    }
    apt::source { 'ubuntu-backports':
        location => $::cfsystem::ubuntu::apt_url,
        release => "${::cfsystem::ubuntu::release}-backports",
        repos => 'main restricted universe multiverse',
        include => { src => false },
    }
    apt::source { 'ubuntu-security':
        location => $::cfsystem::ubuntu::apt_url,
        release => "${::cfsystem::ubuntu::release}-security",
        repos => 'main restricted universe multiverse',
        include => { src => false },
    }

    apt::source { 'puppetlabs':
        location => 'http://apt.puppetlabs.com',
        release => $::cfsystem::ubuntu::release,
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