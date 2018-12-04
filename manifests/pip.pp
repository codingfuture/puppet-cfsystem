#
# Copyright 2017-2018 (c) Andrey Galkin
#

class cfsystem::pip {
    if ($::facts['operatingsystem'] == 'Ubuntu' and
        versioncmp($::facts['operatingsystemrelease'], '18.04') >= 0)
    {
        $easy_install2 = '/usr/bin/pip install'
        $easy_install3 = '/usr/bin/pip3 install'

        package { [
            'python-setuptools', 'python3-setuptools',
            'python-pip', 'python3-pip',
        ]: }
        -> Anchor['cfsystem-pip-install']
    } else {
        $easy_install2 = '/usr/bin/easy_install'
        $easy_install3 = '/usr/bin/easy_install3'

        package { [ 'python-pip', 'python3-pip']:
            ensure => absent,
        }
        -> package { [ 'python-setuptools', 'python3-setuptools' ]: }
        -> Anchor['cfsystem-pip-install']
    }

    # just in case
    anchor { 'cfsystem-pip-install': }
    -> exec { "${easy_install2} pip":
        creates => '/usr/local/bin/pip2',
    }
    -> exec { "${easy_install3} pip":
        creates => '/usr/local/bin/pip3',
    }
    -> package { 'pip':
        ensure   => latest,
        provider => cfpip2,
        require  => Anchor['cfnetwork:firewall'],
    }
    -> package { 'pip3':
        ensure   => latest,
        name     => 'pip',
        provider => pip3,
        require  => Anchor['cfnetwork:firewall'],
    }

    # Allow pip global setup
    cfnetwork::client_port { 'any:cfhttp:root-pip':
        user => 'root',
    }
}
