class cfsystem::debian::packages {
    include cfsystem::debian::cache

    # Infrastructure for debconf
    #---
    file { '/etc/cfsystem/':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    } ->
    file { '/etc/cfsystem/debconf':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    
    # Hardening
    #---
    if !$::cfsystem::allow_nfs {
        package { 'rpcbind': ensure => absent }
        package { 'nfs-common': ensure => absent }
    }
    
    # Essential
    #---
    ensure_packages([
        'etckeeper',
        'apt-transport-https',
        'apt-listchanges',
        'systemd',
    ])
    
    if $::operatingsystem == 'Ubuntu' {
        # See old bug: https://bugs.launchpad.net/ubuntu/+source/glibc/+bug/1394929
        file { '/etc/default/locale':
            content => "
LANG=\"${cfsystem::locale}\"
"
        }
    } else {
        cfsystem::debian::debconf { 'locales':
            config => [
                "locales locales/locales_to_be_generated multiselect ${cfsystem::locale}",
                "locales locales/default_environment_locale select ${cfsystem::locale}",
            ],
        } ->
        package { 'locales-all': }
    }

    # Handy tools
    #---
    ensure_packages([
        'curl',
        'wget',
        'htop',
        'tree',
        'ethtool',
        'iftop',
        'netcat-traditional',
        'netstat-nat',
        'conntrack',
        'telnet',
        'screen',
        'debconf-utils',
        'diffutils',
        'strace',
    ])
    
    # Misc tools which may generate noise
    #---
    ensure_packages([
        'apticron',
        'chkrootkit',
        'rkhunter',
        'debsums',
    ])
}
