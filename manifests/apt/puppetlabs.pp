#
# Copyright 2017-2019 (c) Andrey Galkin
#

# Please see README
class cfsystem::apt::puppetlabs(
    $release
) {
    assert_private()

    package { 'puppetlabs-release': ensure => absent }
    -> package { 'puppetlabs-release-pc1': ensure => absent }
    -> package { 'puppet5-release': ensure => latest }
    # ->
    #class { 'cfsystem::apt::puppetkey':
    #    notify => Exec['cf-apt-update'],
    #}

    apt::source { 'puppet5':
        location => 'http://apt.puppetlabs.com',
        release  => $release,
        repos    => 'puppet5',
        pin      => $cfsystem::apt_pin + 1,
    }
}
