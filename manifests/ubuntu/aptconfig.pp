#
# Copyright 2016 (c) Andrey Galkin
#


# Please see README
class cfsystem::ubuntu::aptconfig {
    # Use for temporary mapping with new releases
    #---
    case $::cfsystem::ubuntu::release {
        'yakkety', 'xenial': {
            $puppet_release = 'xenial'
            $add_backports = false
        }
        default: {
            $puppet_release = $::cfsystem::ubuntu::release
            $add_backports = true
        }
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

    include cfsystem::debian::puppetkey
    apt::source { 'puppetlabs':
        location => 'http://apt.puppetlabs.com',
        release  => $puppet_release,
        repos    => 'PC1',
        pin      => $cfsystem::apt_pin + 1,
    }

    apt::conf { 'local-thin':
        content => [
            'APT::Install-Recommends "0";',
            'APT::Install-Suggests "0";',
            'Acquire::Languages "none";'
        ].join("\n"),
    }

    if $::cfsystem::ubuntu::disable_ipv6 {
        apt::conf { 'force-ipv4':
            content => [
                'Acquire::ForceIPv4 "true";'
            ].join("\n"),
        }
    }

    package { 'puppetlabs-release': ensure => absent }
    package { 'puppetlabs-release-pc1': ensure => absent }
}
