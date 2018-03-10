#
# Copyright 2018 (c) Andrey Galkin
#

class cfsystem::hdsyslog (
    Hash
        $tune = {},
    Cfnetwork::Port
        $port = 515,
) {
    include cfsystem::netsyslog

    $rule_tune = merge(
        {
            'queue.size' => '100000',
            'queue.maxdiskspace' => '3g',
            'queue.timeoutenqueue' => 100,
            'queue.saveonshutdown' => 'on',
        },
        $tune,
        {
            'queue.type' => 'FixedArray',
            'queue.filename' => 'hd',
        }
    )

    #---
    $queue_size = $rule_tune['queue.size']
    $queue_mb = Integer.new( $queue_size / 1024 )

    cfsystem_memory_weight { 'cfsystem:hdsyslog':
        min_mb => $queue_mb,
        max_mb => $queue_mb,
    }

    #---
    file { '/etc/rsyslog.d/10-hdsyslog.conf':
        ensure  => file,
        mode    => '0640',
        content => epp('cfsystem/hdsyslog.conf', {
            tune => $rule_tune,
            port => $port,
        }),
    }
    ~> Exec['cfsystem:rsyslog:refresh']

    #---
    cfnetwork::describe_service { 'hdsyslog':
        server => [
            "tcp/${port}",
            "udp/${port}",
        ]
    }
    cfnetwork::service_port { 'local:hdsyslog': }
}
