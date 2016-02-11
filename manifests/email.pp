class cfsystem::email (
    $smarthost = undef,
    $smarthost_login = undef,
    $smarthost_password = undef,
    $relay_nets = [
        '10.0.0.0/8',
        '192.168.0.0/16',
        '172.16.0.0/12',
    ],
    $listen_ifaces = undef,
    $disable_ipv6 = true,
) {
    include stdlib
    assert_private();
    
    #---
    if $listen_ifaces {
        $listen_iface_ips = any2array($listen_ifaces).map |$iface| {
            split(getparam(Cfnetwork::Iface[$iface], 'address'), '/')[0]
        }
        
        any2array($listen_ifaces).each |$iface| {
            cfnetwork::service_port { "${iface}:smtp:cfsystem": }
        }
    }
    
    if $smarthost {
        $dst_smarthost = any2array($smarthost).map |$sh| { split($sh, ':')[0] }
    }
    
    # Firewall setup
    #---
    cfnetwork::service_port { 'local:smtp:cfsystem': }
    cfnetwork::client_port { 'local:smtp:cfsystem': }
    
    cfnetwork::describe_service { 'cfsmtp':
        server => [
            'tcp/25', # smtp
            'tcp/465', # smtps
            'tcp/587', # submission
        ]
    }
    
    cfnetwork::client_port { 'any:cfsmtp:cfsystem':
        user => ['root', 'Debian-exim'],
        dst => $dst_smarthost
    }

    # OS-specific tune
    #---
    case $::operatingsystem {
        'Debian', 'Ubuntu': {
            $exim_package = 'exim4'
            $exim_service = 'exim4'
            
            exec { 'update-exim4.conf':
                command => '/usr/sbin/update-exim4.conf',
                refreshonly => true,
                require => Package[$exim_package],
                notify => Service[$exim_service],
            }
            
            file { '/etc/exim4/update-exim4.conf.conf':
                content => epp('cfsystem/update-exim4.conf.conf.epp'),
                owner => root,
                group => 'Debian-exim',
                mode => '0640',
                require => Package[$exim_package],
                notify => Exec['update-exim4.conf'],
            }
            file { '/etc/exim4/exim4.conf.localmacros':
                content => epp('cfsystem/exim4.conf.localmacros.epp'),
                owner => root,
                group => 'Debian-exim',
                mode => '0640',
                require => Package[$exim_package],
                notify => Exec['update-exim4.conf'],
            }
            file_line { 'exim_no_disable_ipv6_dups':
                ensure => absent,
                path => '/etc/exim4/exim4.conf.template',
                line => 'disable_ipv6 = true',
                match => 'disable_ipv6',
                match_for_absence => true,
            }
            file { '/etc/exim4/passwd.client':
                content => epp('cfsystem/exim4-passwd.client.epp'),
                owner => root,
                group => root,
                mode => '0644',
                require => Package[$exim_package],
                notify => Exec['update-exim4.conf'],
            }
        }
        default: { fail("Not supported OS ${::operatingsystem}") }
    }

    package { $exim_package: notify => Exec['update-exim4.conf'] }
    service { $exim_service: ensure => running }
    
    # Admin email setup
    #---
    $admin_email = $::cfsystem::admin_email
    
    if $admin_email {
        mailalias{'root':
            recipient => $admin_email,
            notify => Exec['update-exim4.conf'],
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
        notify => Exec['update-exim4.conf'],
    }
    
    # Create test email script
    #---
    file { '/etc/exim4/send_test_email.sh':
        owner => root,
        group => root,
        mode => '0750',
        content => epp('cfsystem/send_test_email.sh.epp'),
        require => Package[$exim_package],
    }
    
    file { '/etc/exim4/clear_queue.sh':
        owner => root,
        group => root,
        mode => '0750',
        require => Package[$exim_package],
        content => "#!/bin/sh\nexiqgrep -i | xargs exim -Mrm",
    }
    
    file { '/etc/exim4/clear_frozen.sh':
        owner => root,
        group => root,
        mode => '0750',
        require => Package[$exim_package],
        content => "#!/bin/sh\nexiqgrep -z -i | xargs exim -Mrm",
    }
}