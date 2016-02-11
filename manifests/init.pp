
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
) {
    include cfnetwork
    include cfauth
    
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
}