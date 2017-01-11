#
# Copyright 2016-2017 (c) Andrey Galkin
#


# Please see README
class cfsystem::debian::aptconfig {
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
    apt::source { 'debian-backports':
        location => $::cfsystem::debian::apt_url,
        release  => "${release}-backports",
        repos    => 'main contrib non-free',
        include  => { src        => false },
        pin      => $cfsystem::apt_backports_pin,
    }
    apt::source { 'debian-security':
        location => $::cfsystem::debian::security_apt_url,
        release  => "${release}/updates",
        repos    => 'main contrib non-free',
        include  => { src        => false },
        pin      => $cfsystem::apt_pin,
    }

    $puppet_release = (versioncmp($::facts['operatingsystemrelease'], '9') >= 0) ? {
        true    => 'jessie',
        default => $::facts['lsbdistcodename']
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

    package { 'puppetlabs-release': ensure => absent }
    package { 'puppetlabs-release-pc1': ensure => absent }
}
