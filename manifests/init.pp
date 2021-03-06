#
# Copyright 2016-2019 (c) Andrey Galkin
#


# Please see README
class cfsystem (
    Boolean $allow_nfs = false,

    Optional[String[1]] $admin_email = undef,

    Optional[Struct[{
        host => String[1],
        port => Cfnetwork::Port,
    }]] $repo_proxy = undef, # proxy host
    Boolean $add_repo_cacher = false, # enable repo cacher service

    String[1] $service_face = $cfsystem::defaults::service_face,

    Variant[ Array[String[1]], String[1] ] $ntp_servers = [
        '0.pool.ntp.org',
        '1.pool.ntp.org',
        '2.pool.ntp.org',
        '3.pool.ntp.org',
    ],
    Boolean $add_ntp_server = false,
    Enum['ntp', 'openntpd', 'chrony', 'systemd'] $ntpd_type = 'systemd',

    String[1] $timezone = 'Etc/UTC',
    Boolean $xen_pv = false, # enable PV/PVH config changes TODO: facter

    Struct[{
        'sources.list'   => Optional[Boolean],
        'sources.list.d' => Optional[Boolean],
        'preferences'    => Optional[Boolean],
        'preferences.d'  => Optional[Boolean],
    }] $apt_purge = {
        'sources.list'   => true,
        'sources.list.d' => true,
        'preferences'    => true,
        'preferences.d'  => true,
    },
    Hash $apt_update = {
        frequency => 'reluctantly',
        timeout   => 300,
        tries     => 2,
    },
    Integer $apt_pin = 1001,
    Integer $apt_backports_pin = 1001,
    String[1] $real_hdd_scheduler = 'deadline',
    Optional[Variant[ String[1], Array[String[1]] ]] $rc_local = undef,

    String[1] $puppet_host = "puppet.${::trusted['domain']}",
    Optional[String[1]] $puppet_cahost = undef,
    String[1] $puppet_env = $::environment,
    Boolean $puppet_use_dns_srv = false,

    Boolean $agent = false,
    Boolean $mcollective = false,

    String[1] $locale = 'en_US.UTF-8',

    Integer[0] $reserve_ram = 128,

    String[1] $key_server = 'hkp://keyserver.ubuntu.com:80',

    Boolean $random_feed = true,
    Boolean $add_handy_tools = true,

    String[1] $puppet_backup_age = '1d',
) inherits cfsystem::defaults {
    include cfnetwork
    include cfauth

    #---
    cfsystem_flush_config { 'begin': }
    -> cfsystem_flush_config { 'commit': }

    cfsystem_memory_weight { 'cfsystem':
        ensure => present,
        weight => 1,
        min_mb => $reserve_ram,
    }
    cfsystem_memory_calc { 'total': ensure => present }

    #---
    if $::cfsystem::add_repo_cacher and !$::facts['cf_has_acng'] {
        $repo_proxy_cond = undef
        $http_proxy = ''
    } else {
        $repo_proxy_cond = $repo_proxy

        $http_proxy = $repo_proxy ? {
            undef => '',
            default => "http://${repo_proxy['host']}:${repo_proxy['port']}"
        }
    }

    ensure_packages(['wget'])

    if $http_proxy and $http_proxy != '' {
        Package['wget']
        -> file_line { 'wgetrc_http_proxy':
            path     => '/etc/wgetrc',
            line     => "http_proxy = ${http_proxy}",
            match    => 'http_proxy',
            multiple => true,
        }
        -> file_line { 'wgetrc_https_proxy':
            path     => '/etc/wgetrc',
            line     => "https_proxy = ${http_proxy}",
            match    => 'https_proxy',
            multiple => true,
        }
    } else {
        Package['wget']
        -> file_line { 'wgetrc_http_proxy':
            path     => '/etc/wgetrc',
            line     => '# http_proxy = ',
            match    => 'http_proxy',
            multiple => true,
        }
        -> file_line { 'wgetrc_https_proxy':
            path     => '/etc/wgetrc',
            line     => '# https_proxy = ',
            match    => 'https_proxy',
            multiple => true,
        }
    }

    #---
    class { 'cfsystem::custombin': stage => 'setup' }

    cfsystem::binpath { 'cfsystem_paths':
        bin_dir => $cfsystem::custombin::bin_dir,
    }
    cfsystem::binpath { 'puppet_paths':
        bin_dir => '/opt/puppetlabs/bin',
    }

    file { '/etc/sudoers.d/secure_path':
        ensure  => present,
        mode    => '0440',
        replace => false,
        content => '',
    }
    -> cfsystem_secure_path { '!default':
        ensure => present,
        path   => $cfauth::secure_path,
    }

    #---
    case $::operatingsystem {
        'Debian': { include cfsystem::debian }
        'Ubuntu': { include cfsystem::ubuntu }
        default: { fail("Not supported OS ${::operatingsystem}") }
    }

    include cfsystem::hierapool
    include cfsystem::sysctl
    include cfsystem::email
    include cfsystem::ntp
    include cfsystem::git
    include cfsystem::startup

    #---
    cfnetwork::describe_service{ 'puppet': server => 'tcp/8140' }
    cfnetwork::client_port{ 'any:puppet:cfsystem': user => 'root' }

    #---
    $certname = $::trusted['certname'];
    file { '/etc/hostname':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0644',
        replace => true,
        content => "${certname}\n",
    }

    #---
    file { '/etc/rc.local':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0755',
        replace => true,
        content => epp('cfsystem/rc.local.epp'),
        notify  => Exec['rc.local-update'],
    }
    exec { 'rc.local-update':
      command     => '/etc/rc.local',
      refreshonly => true,
    }

    #---
    package { 'puppet-agent': }

    if !member(lookup('classes', Array[String], 'unique'), 'cfpuppetserver') and
        !defined(Class['cfpuppetserver']
    ) {
        file {'/etc/puppetlabs/puppet/puppet.conf':
            mode    => '0644',
            content => epp('cfsystem/puppet.conf.epp'),
            require => Package['puppet-agent']
        }
    }

    # Cleanup local backups
    tidy { '/opt/puppetlabs/puppet/cache/clientbucket/':
        age     => $puppet_backup_age,
        recurse => true,
        rmdirs  => true,
        backup  => false,
    }

    #---
    exec { 'cfsystem-systemd-reload':
        command     => '/bin/systemctl daemon-reload',
        refreshonly => true,
    }

    ensure_resource('service', 'puppet', {
        ensure   => $agent,
        enable   => $agent ? { false => mask, default => $agent },
        provider => 'systemd',
    })
    ensure_resource('service', 'pxp-agent', {
        ensure   => $agent,
        enable   => $agent ? { false => mask, default => $agent },
        provider => 'systemd',
    })
    ensure_resource('service', 'mcollective', {
        ensure   => $mcollective,
        enable   => $mcollective ? { false => mask, default => $mcollective },
        provider => 'systemd',
    })

    $systemd_wants_dir = '/etc/systemd/system/multi-user.target.wants'

    if !$agent {
        file { "${systemd_wants_dir}/puppet.service":
            ensure => absent,
            notify => Exec['cfsystem-systemd-reload'],
        }
        file { "${systemd_wants_dir}/pxp-agent.service":
            ensure => absent,
            notify => Exec['cfsystem-systemd-reload'],
        }
    }

    if !$mcollective {
        file { "${systemd_wants_dir}/mcollective.service":
            ensure => absent,
            notify => Exec['cfsystem-systemd-reload'],
        }
    }

    #---
    if $random_feed {
        include cfsystem::randomfeed
    }

    #---
    $location = pick(
        $cfsystem::hierapool::location,
        $::facts['cf_location'],
        ''
    )

    #---
    include cfsystem::hwm
}
