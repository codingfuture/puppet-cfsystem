
class cfsystem (
    Boolean $allow_nfs = false,
    
    Optional[String] $admin_email = undef,

    Optional[Hash] $repo_proxy = undef, # proxy host
    Boolean $add_repo_cacher = false, # enable repo cacher service

    String $service_face = 'any',
    
    Variant[ Array[String], String ] $ntp_servers = [ 'pool.ntp.org' ],
    Boolean $add_ntp_server = false,
    
    String $timezone = 'Etc/UTC',
    Boolean $xen_pv = false, # enable PV/PVH config changes TODO: facter
    
    Hash $apt_purge = {
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
    String $real_hdd_scheduler = 'deadline',
    Optional[Variant[ String, Array[String] ]] $rc_local = undef,
    
    String $puppet_host = "puppet.${::trusted['domain']}",
    Optional[String] $puppet_cahost = undef,
    String $puppet_env = $::environment,
    Boolean $puppet_use_dns_srv = false,
    
    Boolean $agent = false,
    Boolean $mcollective = false,
    
    String $locale = 'en_US.UTF-8',
    
    Integer $reserve_ram = 128,
    
    String $key_server = 'hkp://pgp.mit.edu:80',
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
    if $::cfsystem::add_repo_cacher and !$cf_has_acng {
        $repo_proxy_cond = undef
        $http_proxy = ''
    } else {
        $repo_proxy_cond = $repo_proxy
        
        $http_proxy = $repo_proxy ? {
            undef => '',
            default => "http://${repo_proxy['host']}:${repo_proxy['port']}"
        }
    }
    
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
       !defined(Class['cfpuppetserver'])
    {
        file {'/etc/puppetlabs/puppet/puppet.conf':
            mode    => '0644',
            content => epp('cfsystem/puppet.conf.epp'),
            require => Package['puppet-agent']
        }
    }
    
    #---
    ensure_resource('service', 'puppet', {
        ensure => $agent,
        enable => $agent,
    })
    ensure_resource('service', 'mcollective', {
        ensure => $mcollective,
        enable => $mcollective,
    })

}