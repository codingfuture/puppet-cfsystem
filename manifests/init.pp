#
# Copyright 2016-2017 (c) Andrey Galkin
#


# Please see README
class cfsystem (
    Boolean $allow_nfs = false,

    Optional[String[1]] $admin_email = undef,

    Optional[Struct[{
        host => String[1],
        port => Integer[1,65535],
    }]] $repo_proxy = undef, # proxy host
    Boolean $add_repo_cacher = false, # enable repo cacher service

    String[1] $service_face = 'any',

    Variant[ Array[String[1]], String[1] ] $ntp_servers = [ 'pool.ntp.org' ],
    Boolean $add_ntp_server = false,
    Enum['ntp', 'openntpd', 'chrony'] $ntpd_type = 'ntp',

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
        frequency => 'daily',
        timeout   => 300,
    },
    Integer $apt_pin = 1001,
    Integer $apt_backports_pin = 600,
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
) {
    include cfnetwork
    include cfauth

    #---
    cfsystem_flush_config { 'begin': ensure => present }
    cfsystem_flush_config { 'commit': ensure => present }
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
        Package['wget'] ->
        file_line { 'wgetrc_http_proxy':
            path     => '/etc/wgetrc',
            line     => "http_proxy = ${http_proxy}",
            match    => 'http_proxy',
            multiple => true,
        } ->
        file_line { 'wgetrc_https_proxy':
            path     => '/etc/wgetrc',
            line     => "https_proxy = ${http_proxy}",
            match    => 'https_proxy',
            multiple => true,
        }
    } else {
        Package['wget'] ->
        file_line { 'wgetrc_http_proxy':
            path     => '/etc/wgetrc',
            line     => '# http_proxy = ',
            match    => 'http_proxy',
            multiple => true,
        } ->
        file_line { 'wgetrc_https_proxy':
            path     => '/etc/wgetrc',
            line     => '# https_proxy = ',
            match    => 'https_proxy',
            multiple => true,
        }
    }

    #---
    class { 'cfsystem::custombin': stage => 'setup' }

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

    #---
    exec { 'cfsystem-systemd-reload':
        command     => '/bin/systemctl daemon-reload',
        refreshonly => true,
    }

    ensure_resource('service', 'puppet', {
        ensure   => $agent,
        enable   => $agent,
        provider => 'systemd',
    })
    ensure_resource('service', 'pxp-agent', {
        ensure   => $agent,
        enable   => $agent,
        provider => 'systemd',
    })
    ensure_resource('service', 'mcollective', {
        ensure   => $mcollective,
        enable   => $mcollective,
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
    include cfsystem::hwm
}
