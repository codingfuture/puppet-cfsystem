
# Please see README
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
        target => "/usr/share/zoneinfo/${cfsystem::timezone}"
    }

    $type = $cfsystem::ntpd_type

    case $type {
        'ntp': {
            $absent =  ['openntpd', 'chrony']
            $conf = '/etc/ntp.conf'
            $tpl = 'cfsystem/ntpd.conf.epp'
            $user = 'ntp'
        }
        'openntpd': {
            $absent =  ['ntp', 'chrony']
            $conf = '/etc/openntpd/ntpd.conf'
            $tpl = 'cfsystem/openntp.conf.epp'
            $user = 'ntpd'
        }
        'chrony': {
            $absent =  ['openntpd', 'ntp']
            $conf = '/etc/chrony/chrony.conf'
            $tpl = 'cfsystem/chrony.conf.epp'
            $user = '_chrony'
        }
        default: {
            fail("Not implemented NTPd type: ${type}")
        }
    }

    package { $absent: ensure => absent } ->
    package { $type: ensure => present } ->
    file { $conf:
        mode    => '0644',
        content => epp($tpl),
        notify  => Service[$type],
    } ->
    service { $type:
        ensure => running,
        enable => true,
    }

    package { 'ntpdate': }

    #
    cfnetwork::client_port { 'any:ntp:cfsystem':
        user => ['root', $user],
        # it generates side effects on dynamic DNS
        #dst => $cfsystem::ntp_servers,
    }

    if $cfsystem::add_ntp_server {
        cfnetwork::service_port { "${cfsystem::service_face}:ntp": }
    }

}
