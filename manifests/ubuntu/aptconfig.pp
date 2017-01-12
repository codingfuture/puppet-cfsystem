#
# Copyright 2016-2017 (c) Andrey Galkin
#


# Please see README
class cfsystem::ubuntu::aptconfig {
    # Use for temporary mapping with new releases
    #---
    if versioncmp($::facts['operatingsystemrelease'], '16.10') >= 0 {
        $puppet_release = 'xenial'
        $add_backports = false
    } else {
        $puppet_release = $::facts['lsbdistcodename']
        $add_backports = true
    }

    #---
    class {'apt':
        proxy  => $::cfsystem::repo_proxy_cond,
        update => $::cfsystem::apt_update,
        purge  => $::cfsystem::apt_purge,
    }

    #---
    apt::source { 'ubuntu':
        location => $::cfsystem::ubuntu::apt_url,
        release  => $::cfsystem::ubuntu::release,
        repos    => 'main restricted universe multiverse',
        include  => { src        => false },
        pin      => $cfsystem::apt_pin,
    }
    apt::source { 'ubuntu-updates':
        location => $::cfsystem::ubuntu::apt_url,
        release  => "${::cfsystem::ubuntu::release}-updates",
        repos    => 'main restricted universe multiverse',
        include  => { src        => false },
        pin      => $cfsystem::apt_pin,
    }

    if $add_backports {
        apt::source { 'ubuntu-backports':
            location => $::cfsystem::ubuntu::apt_url,
            release  => "${::cfsystem::ubuntu::release}-backports",
            repos    => 'main restricted universe multiverse',
            include  => { src            => false },
            pin      => $cfsystem::apt_backports_pin,
        }
    }

    apt::source { 'ubuntu-security':
        location => $::cfsystem::ubuntu::apt_url,
        release  => "${::cfsystem::ubuntu::release}-security",
        repos    => 'main restricted universe multiverse',
        include  => { src        => false },
        pin      => $cfsystem::apt_pin,
    }

    class { 'cfsystem::apt::common':
        puppet_release => $puppet_release,
        force_ipv4     => $::cfsystem::ubuntu::disable_ipv6,
    }
}
