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
    package { 'systemd': }

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
}
