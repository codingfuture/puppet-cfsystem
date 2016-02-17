
class cfsystem::debian (
    $apt_url = 'http://httpredir.debian.org/debian',
    $security_apt_url = 'http://security.debian.org/',
    $release = 'jessie',
) {
    include stdlib
    assert_private();
    
    class { 'cfsystem::debian::aptconfig': stage => 'setup' }
    
    include cfsystem::debian::packages
    
    if $::cf_virt_detect == 'xen' {
        file_line { 'xenpv_initab_disable_serial':
            ensure  => present,
            path    => '/etc/inittab',
            line    => '#T0:23:respawn:/sbin/getty -L ttyS0 9600 vt100',
            match   => '^T0',
            replace => true,
        }
        file_line { 'xenpv_initab_enable_hvc':
            ensure  => present,
            path    => '/etc/inittab',
            line    => 'co:2345:respawn:/sbin/getty hvc0 9600 linux',
            match   => '^#co',
            replace => true,
        }
    }
}