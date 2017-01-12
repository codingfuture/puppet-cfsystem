#
# Copyright 2016-2017 (c) Andrey Galkin
#


# Please see README
class cfsystem::debian::aptconfig {
    # Use for temporary mapping with new releases
    #---
    if versioncmp($::facts['operatingsystemrelease'], '9') >= 0 {
        $puppet_release = 'jessie'
        $prevrelease = 'jessie'
        $add_backports = false
    } else {
        $puppet_release = $::facts['lsbdistcodename']
        $add_backports = true
        $prevrelease = undef
    }

    class {'apt':
        proxy  => $::cfsystem::repo_proxy_cond,
        update => $::cfsystem::apt_update,
        purge  => $::cfsystem::apt_purge,
    }

    #---
    $release = $::cfsystem::debian::release ? {
        'testing' => 'stretch',
        default   => $::cfsystem::debian::release
    }
    apt::source { 'debian':
        location => $::cfsystem::debian::apt_url,
        release  => $release,
        repos    => 'main contrib non-free',
        include  => { src        => false },
        pin      => $cfsystem::apt_pin,
    }
    apt::source { 'debian-updates':
        location => $::cfsystem::debian::apt_url,
        release  => "${release}-updates",
        repos    => 'main contrib non-free',
        include  => { src        => false },
        pin      => $cfsystem::apt_pin,
    }

    if $add_backports {
        apt::source { 'debian-backports':
            location => $::cfsystem::debian::apt_url,
            release  => "${release}-backports",
            repos    => 'main contrib non-free',
            include  => { src        => false },
            pin      => $cfsystem::apt_backports_pin,
        }
    }

    apt::source { 'debian-security':
        location => $::cfsystem::debian::security_apt_url,
        release  => "${release}/updates",
        repos    => 'main contrib non-free',
        include  => { src        => false },
        pin      => $cfsystem::apt_pin,
    }

    if $prevrelease {
        apt::source { 'debian-old':
            location => $::cfsystem::debian::apt_url,
            release  => $prevrelease,
            repos    => 'main contrib non-free',
            include  => { src        => false },
            pin      => 100,
        }
        apt::source { 'debian-old-security':
            location => $::cfsystem::debian::security_apt_url,
            release  => "${prevrelease}/updates",
            repos    => 'main contrib non-free',
            include  => { src        => false },
            pin      => 110,
        }
    }

    class { 'cfsystem::apt::common':
        puppet_release => $puppet_release,
    }
}
