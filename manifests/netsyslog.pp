#
# Copyright 2018 (c) Andrey Galkin
#

class cfsystem::netsyslog {
    include cfnetwork

    cfnetwork::describe_service { 'netsyslog':
        server => [
            'tcp/514',
            'udp/514',
        ]
    }
    cfnetwork::service_port { 'local:netsyslog': }

    file { '/etc/rsyslog.d/00-netsyslog.conf':
        ensure  => file,
        mode    => '0640',
        content => file('cfsystem/netsyslog.conf'),
    }
    ~> Exec['cfsystem:rsyslog:refresh']
}
