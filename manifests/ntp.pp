
class cfsystem::ntp {
    include stdlib
    assert_private();
    
    file {'/etc/timezone':
        mode    => '0644',
        content => "${cfsystem::timezone}\n",
    }
    file {'/etc/localtime':
        ensure => link,
        mode   => '0644',
        target => "/usr/share/zoneinfo/${cfsystem::timezone}"
    }
    
    cfnetwork::client_port { 'any:ntp:cfsystem':
        user => ['root', 'ntpd'],
        # it generates side effects on dynamic DNS
        #dst => $cfsystem::ntp_servers,
    }
    
    if $cfsystem::add_ntp_server {
        cfnetwork::service_port { "${cfsystem::service_face}:ntp": }
    }
    
    package { 'openntpd': } ->
    file { '/etc/openntpd/ntpd.conf':
        mode => '0644',
        content => epp('cfsystem/openntp.conf.epp'),
    } ->
    service { 'openntpd': ensure => running }
}
