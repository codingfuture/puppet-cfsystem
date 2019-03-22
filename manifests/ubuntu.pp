#
# Copyright 2016-2019 (c) Andrey Galkin
#


# Please see README
class cfsystem::ubuntu (
    String[1] $apt_url = 'http://archive.ubuntu.com/ubuntu',
    String[1] $release = $::facts['lsbdistcodename'],
    Boolean $disable_ipv6 = true,
) {
    include stdlib
    assert_private();

    class { 'cfsystem::ubuntu::aptconfig': stage => 'setup' }

    include cfsystem::debian::packages
}
