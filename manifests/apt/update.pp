#
# Copyright 2017-2018 (c) Andrey Galkin
#


# Please see README
class cfsystem::apt::update {
    assert_private()

    exec { 'cf-apt-update':
        command     => '/usr/bin/apt-get update',
        logoutput   => 'on_failure',
        refreshonly => true,
    }
}
