
class cfsystem::ntp {
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
