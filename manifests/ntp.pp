
class cfsystem::ntp {
    include stdlib
    assert_private();
    
    case $::operatingsystem {
        'Debian', 'Ubuntu': {
            $zonecomp = split($cfsystem::timezone, '/')
            
            if size($zonecomp) != 2 {
                fail('Timezone must be in {Area}/{Zone} format. Examples: Etc/UTC, Europe/Riga')
            }
            
            $area = $zonecomp[0]
            $zone = $zonecomp[1]
            
            cfsystem::debian::debconf { 'tzdata':
                config => [
                    "tzdata  tzdata/Areas select ${area}",
                    "tzdata  tzdata/Zones/${area} select ${zone}",
                ],
            }
        }
        default: { fail("Not supported OS ${::operatingsystem}") }
    }
    
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
        mode    => '0644',
        content => epp('cfsystem/openntp.conf.epp'),
    } ->
    service { 'openntpd': ensure => running }
}
