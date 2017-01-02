#
# Copyright 2016-2017 (c) Andrey Galkin
#


# Please see README
class cfsystem::ubuntu (
    #$apt_url = 'mirror://mirrors.ubuntu.com/mirrors.txt',
    String[1] $apt_url = 'http://ftp.halifax.rwth-aachen.de/ubuntu/',
    String[1] $release = $::facts['lsbdistcodename'],
    Boolean $disable_ipv6 = true,
) {
    include stdlib
    assert_private();

    class { 'cfsystem::ubuntu::aptconfig': stage => 'setup' }

    include cfsystem::debian::packages
}
