class cfsystem::debian::packages {
    include cfsystem::debian::cache

    # Hardening
    #---
    if !$::cfsystem::allow_nfs {
        package { 'rpcbind': ensure => absent }
        package { 'nfs-common': ensure => absent }
    }
    
    # Essential
    #---
    package { 'sudo': }
    package { 'openssh-server': }
    package { 'etckeeper': }
    package { 'apt-transport-https': }

    # Handy tools
    #---
    package { 'curl': }
    package { 'wget': }
    #package { 'git': }
    package { 'htop': }
    package { 'tree': }
    package { 'ethtool': }
    package { 'iftop': }
    package { 'netcat-traditional': }
    package { 'netstat-nat': }
    package { 'conntrack': }
    package { 'telnet': }
    package { 'screen': }
    
    # Misc tools which may generate noise
    #---
    package { 'apticron': }
    package { 'chkrootkit': }
    package { 'rkhunter': }
    package { 'debsums': }
    
        
    #---
    cfnetwork::client_port { 'any:ntp:cfsystem':
        user => ['root', 'ntpd'],
        # it generates side effects on dynamic DNS
        #dst => $cfsystem::ntp_servers,
    }
    
    if $cfsystem::add_ntp_server {
        cfnetwork::service_port { "${cfsystem::service_face}:ntp": }
        $ntp_listen = '0.0.0.0'
    }

    class { 'openntp':
        ensure       => present,
        enable       => true,
        listen       => $ntp_listen,
        server       => any2array($cfsystem::ntp_servers),
        package_name => 'openntpd',
        service_name => 'openntpd',
        config_file  => '/etc/openntpd/ntpd.conf',
    }
    
    # Git config
    #---
    include git
    $certname = $::trusted['certname']
    git::config { 'user.name': value => 'Root' }
    git::config { 'user.email': value => "root@${certname}" }
}