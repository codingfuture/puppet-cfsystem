#
# Copyright 2016-2019 (c) Andrey Galkin
#


# Please see README
class cfsystem::hwm::dell(
    String[1] $community_repo = 'http://linux.dell.com/repo/community',
) {
    assert_private();

    case $::operatingsystem {
        'Debian', 'Ubuntu': {
            class { 'cfsystem::hwm::dell::aptrepo': stage => 'setup' }
            ensure_packages([
                'srvadmin-base',
                'srvadmin-idracadm8',
                'srvadmin-storage-cli',
                'srvadmin-omcommon',
                'syscfg',
            ])
            service { 'dataeng':
                ensure   => running,
                enable   => true,
                provider => 'systemd',
                require  => [
                    Package['srvadmin-base'],
                    Package['srvadmin-omcommon'],
                ]
            }
        }
        default : {
            fail("Dell supported is not implemented for this OS: ${::operatingsystem}")
        }
    }
}
