
class cfsystem (
    $allow_nfs = false,
    
    $admin_email = undef,

    $repo_proxy = undef, # proxy host
    $add_repo_cacher = false, # enable repo cacher service

    $service_face = 'any',
    
    $ntp_servers = [ 'pool.ntp.org' ],
    $add_ntp_server = false,
    
    $timezone = 'Etc/UTC',
    $xen_pv = false, # enable PV/PVH config changes TODO: facter
    
    $apt_purge = {
        'sources.list'   => true,
        'sources.list.d' => true,
        'preferences'    => true,
        'preferences.d'  => true,
    },
    $apt_update = {
        frequency => 'daily',
        timeout   => 300,
    },
    $real_hdd_scheduler = 'deadline',
    $rc_local = undef,
) {
    include cfnetwork
    include cfauth
    
    if $::cfsystem::add_repo_cacher and !$cf_has_acng {
        $repo_proxy_cond = undef
    } else {
        $repo_proxy_cond = $repo_proxy
    }
    
    case $::operatingsystem {
        'Debian': { include cfsystem::debian }
        'Ubuntu': { include cfsystem::ubuntu }
        default: { fail("Not supported OS ${::operatingsystem}") }
    }
    
    class { 'timezone':
        timezone => $timezone,
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
      command     => "/etc/rc.local",
      refreshonly => true,
    }

}