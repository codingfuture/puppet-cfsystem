#
# Copyright 2016-2017 (c) Andrey Galkin
#


# Please see README
class cfsystem::email (
    Optional[String[1]] $smarthost = undef,
    Optional[String[1]] $smarthost_login = undef,
    Optional[String[1]] $smarthost_password = undef,
    Variant[ Array[String[1]], String[1]] $relay_nets = [
        '10.0.0.0/8',
        '192.168.0.0/16',
        '172.16.0.0/12',
    ],
    Optional[Variant[Array[String[1]], String[1]]] $listen_ifaces = undef,
    Boolean $disable_ipv6 = true,
) {
    include stdlib
    include cfsystem::custombin
    assert_private();

    #---
    if $listen_ifaces {
        $listen_iface_ips = any2array($listen_ifaces).map |$iface| {
            cf_get_bind_address($iface)
        }

        any2array($listen_ifaces).each |$iface| {
            cfnetwork::service_port { "${iface}:smtp:cfsystem": }
        }
    } else {
        $listen_iface_ips = undef
    }

    if $smarthost {
        $dst_smarthost = any2array($smarthost).map |$sh| { split($sh, ':')[0] }
    } else {
        $dst_smarthost = undef
    }

    # Firewall setup
    #---
    cfnetwork::service_port { 'local:smtp:cfsystem': }
    cfnetwork::client_port { 'local:smtp:cfsystem': }

    cfnetwork::describe_service { 'smtp':
        server => 'tcp/25', # smtp
    }

    cfnetwork::describe_service { 'cfsmtp':
        server => [
            'tcp/25', # smtp
            'tcp/465', # smtps
            'tcp/587', # submission
        ]
    }

    # NOTE: it must be defined even with undef smart host
    cfnetwork::client_port { 'any:cfsmtp:cfsystem':
        user => ['root', 'Debian-exim'],
        dst  => $dst_smarthost
    }

    # OS-specific tune
    #---
    case $::operatingsystem {
        'Debian', 'Ubuntu': {
            $exim_package = 'exim4'
            $exim_service = 'exim4'

            exec { 'update-exim4.conf':
                command     => '/usr/sbin/update-exim4.conf',
                refreshonly => true,
                require     => Package[$exim_package],
                notify      => Service[$exim_service],
            }

            file { '/etc/exim4/update-exim4.conf.conf':
                content => epp('cfsystem/update-exim4.conf.conf.epp'),
                owner   => root,
                group   => 'Debian-exim',
                mode    => '0640',
                require => Package[$exim_package],
                notify  => Exec['update-exim4.conf'],
            }
            file { '/etc/exim4/exim4.conf.localmacros':
                content => epp('cfsystem/exim4.conf.localmacros.epp'),
                owner   => root,
                group   => 'Debian-exim',
                mode    => '0640',
                require => Package[$exim_package],
                notify  => Exec['update-exim4.conf'],
            }
            file_line { 'exim_no_disable_ipv6_dups':
                ensure            => absent,
                path              => '/etc/exim4/exim4.conf.template',
                line              => 'disable_ipv6 = true',
                match             => 'disable_ipv6',
                match_for_absence => true,
                require           => Package[$exim_package],
                notify            => Exec['update-exim4.conf'],
            }
            file { '/etc/exim4/passwd.client':
                content => epp('cfsystem/exim4-passwd.client.epp'),
                owner   => root,
                group   => root,
                mode    => '0644',
                require => Package[$exim_package],
                notify  => Exec['update-exim4.conf'],
            }
        }
        default: { fail("Not supported OS ${::operatingsystem}") }
    }

    package { $exim_package: notify => Exec['update-exim4.conf'] }
    service { $exim_service:
        ensure   => running,
        enable   => true,
        provider => 'systemd',
    }

    # Admin email setup
    #---
    $admin_email = $::cfsystem::admin_email

    if $admin_email {
        mailalias{'root':
            recipient => $admin_email,
            notify    => Exec['update-exim4.conf'],
        }
    }

    # Config exim
    #---
    $certname = $::trusted['certname'];
    file { '/etc/mailname':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0644',
        replace => true,
        content => "${certname}\n",
        notify  => Exec['update-exim4.conf'],
    }

    # Create test email script
    #---
    file { "${cfsystem::custombin::bin_dir}/cf_send_test_email":
        owner   => root,
        group   => root,
        mode    => '0750',
        content => epp('cfsystem/send_test_email.sh.epp'),
        require => Package[$exim_package],
    }

    file { "${cfsystem::custombin::bin_dir}/cf_clear_email_queue":
        owner   => root,
        group   => root,
        mode    => '0750',
        require => Package[$exim_package],
        content => "#!/bin/sh\nexiqgrep -i | /usr/bin/xargs exim -Mrm",
    }

    file { "${cfsystem::custombin::bin_dir}/cf_clear_frozen_emails":
        owner   => root,
        group   => root,
        mode    => '0750',
        require => Package[$exim_package],
        content => "#!/bin/sh\nexiqgrep -z -i | /usr/bin/xargs exim -Mrm",
    }
}
