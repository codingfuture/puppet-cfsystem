
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
                ensure  => running,
                enable  => true,
                require => Package['srvadmin-base'],
            }
        }
    }
}
