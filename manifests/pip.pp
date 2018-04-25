#
# Copyright 2017-2018 (c) Andrey Galkin
#

class cfsystem::pip {
    package { [ 'python-pip', 'python3-pip']:
        ensure => absent,
    }
    -> package { [ 'python-setuptools', 'python3-setuptools' ]: }
    # just in case
    -> exec { '/usr/bin/easy_install pip':
        creates => '/usr/local/bin/pip2',
    }
    -> exec { '/usr/bin/easy_install3 pip':
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
    cfnetwork::client_port { 'any:http:root-pip':
        user => 'root',
    }
    cfnetwork::client_port { 'any:https:root-pip':
        user => 'root',
    }
}
