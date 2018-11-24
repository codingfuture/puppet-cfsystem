#
# Copyright 2016-2018 (c) Andrey Galkin
#


# Please see README
class cfsystem::ntp(
    String[1] $cron_hour = '*',
    String[1] $cron_minute = '*/10',
) {
    include stdlib
    assert_private();

    $opsystem = $::facts['operatingsystem']

    case $opsystem {
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
        default: { fail("Not supported OS ${opsystem}") }
    }

    file {'/etc/timezone':
        mode    => '0644',
        content => "${cfsystem::timezone}\n",
    }

    file {'/etc/localtime':
        ensure => link,
        target => "/usr/share/zoneinfo/${cfsystem::timezone}"
    }

    if $cfauth::freeipa and $cfsystem::ntpd_type != 'chrony' {
        if ($opsystem == 'Ubuntu' and versioncmp($::facts['operatingsystemrelease'], '18.04') < 0) {
            $type = 'ntp'
        } else {
            $type = 'chrony'
        }

        cf_notify { 'cfsystem::chrony::fallback':
            message  => "Forcing '${type}' NTP due to FreeIPA requirement",
            loglevel => warning,
        }
    } elsif $cfsystem::add_ntp_server and $cfsystem::ntpd_type == 'systemd'  {
        $type = 'ntp'

        cf_notify { 'cfsystem::ntp::fallback':
            message  => 'systemd-timesyncd can not act as server, fallback to ntp',
            loglevel => warning,
        }
    } else {
        $type = $cfsystem::ntpd_type
    }

    case $type {
        'systemd': {
            $absent =  ['openntpd', 'chrony', 'ntp']
            $conf = '/etc/systemd/timesyncd.conf'
            $tpl = 'cfsystem/timesyncd.conf.epp'
            $user = 'systemd-timesync'

            # Newer systemd uses DynamicUser what is problematic for firewall
            exec { 'Cfsystem stop systemd-timesyncd':
                command => '/bin/systemctl stop systemd-timesyncd.service',
                unless  => "/usr/bin/id -Gnz ${user}",
            }
            -> group { $user: ensure => present }
            -> user { $user:
                ensure => present,
                gid    => $user,
                home   => '/run/systemd',
                shell  => '/bin/false',
                system => true,
            }
            -> Anchor['cfnetwork:pre-firewall']
        }
        'ntp': {
            $absent =  ['openntpd', 'chrony']
            $conf = '/etc/ntp.conf'
            $tpl = 'cfsystem/ntpd.conf.epp'
            $user = 'ntp'

            # for internal NTPd connections
            cfnetwork::service_port { 'local:ntp': }
            cfsystem::metric { 'ntpd': }
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
            cfsystem::metric { 'chrony': }
        }
        default: {
            fail("Not implemented NTPd type: ${type}")
        }
    }

    package { $absent: ensure => absent }

    if $type == 'systemd' {
        Package[$absent]
        -> file { $conf:
            mode    => '0644',
            content => epp($tpl),
        }
        ~> Exec['cfsystem-systemd-reload']
        -> service { 'systemd-timesyncd':
            ensure   => running,
            enable   => true,
            provider => 'systemd',
        }
    } else {
        Package[$absent]
        -> package { $type: ensure => present }
        -> file { $conf:
            mode    => '0644',
            content => epp($tpl),
            notify  => Service[$type],
        }
        -> service { 'systemd-timesyncd':
            ensure   => stopped,
            enable   => false,
            provider => 'systemd',
        }
        -> service { $type:
            ensure   => running,
            enable   => true,
            provider => 'systemd',
        }
    }

    #
    include cfsystem::custombin

    package { 'ntpdate': }
    -> cron { 'cf_ntpdate':
        command => [
            $cfsystem::custombin::cf_ntpdate,
            ' | /bin/egrep \'offset [0-9]*[1-9]\.[0-9]+ sec\'',
        ].join(''),
        hour    => $cron_hour,
        minute  => $cron_minute,
    }
    cfauth::sudoentry { "${cfauth::admin_user}_ntpdate":
        command => $cfsystem::custombin::cf_ntpdate,
        user    => $cfauth::admin_user,
    }

    #
    cfnetwork::client_port { 'any:ntp:cfsystem':
        user => ['root', $user],
        # it generates side effects on dynamic DNS
        #dst => $cfsystem::ntp_servers,
    }

    if $cfsystem::add_ntp_server {
        cfnetwork::service_port { "${cfsystem::service_face}:ntp":
            src => 'ipset:localnet',
        }
    }

    #---
    if $type == 'systemd' {
        $systemd_ensure = true

        exec { 'systemd-timesyncd ntp':
            command => '/usr/bin/timedatectl set-ntp yes',
            unless  => '/bin/systemctl is-enabled systemd-timesyncd.service',
        }
    } else {
        $systemd_ensure = false

        exec { 'systemd-timesyncd ntp':
            command => '/usr/bin/timedatectl set-ntp no',
            onlyif  => '/bin/systemctl is-enabled systemd-timesyncd.service',
        }
    }

    Exec['systemd-timesyncd ntp']
    -> service { 'systemd-timesyncd.service':
        ensure => $systemd_ensure,
        enable => $systemd_ensure,
    }
}
