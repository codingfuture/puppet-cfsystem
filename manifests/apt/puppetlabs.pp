#
# Copyright 2017 (c) Andrey Galkin
#

# Please see README
class cfsystem::apt::puppetlabs(
    $release
) {
    assert_private()

    package { 'puppetlabs-release': ensure => absent } ->
    package { 'puppetlabs-release-pc1': ensure => latest }
    # ->
    #class { 'cfsystem::apt::puppetkey':
    #    notify => Exec['cf-apt-update'],
    #}

    apt::source { 'puppetlabs-pc1':
        location      => 'http://apt.puppetlabs.com',
        release       => $release,
        repos         => 'PC1',
        pin           => $cfsystem::apt_pin + 1,
        notify_update => false,
        notify        => Exec['cf-apt-update'],
    }
}
