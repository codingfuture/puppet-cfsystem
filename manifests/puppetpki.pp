
define cfsystem::puppetpki(
    String $user = $title,
    Boolean $copy_key = true,
    Optional[String] $pki_dir = undef,
) {
    $group = pick(getparam(User[$user], 'group'), $user)
    
    if $pki_dir {
        $q_pki_dir = $pki_dir
    } else {
        $home = getparam(User[$user], 'home')
        
        if !$home or $home == '' {
            fail("User ${user} must be defined with explicit 'home' parameter")
        }
        
        $q_pki_dir = "${home}/pki"
    }
    
    $dst_dir = "${q_pki_dir}/puppet"
    $puppet_ssl_dir = '/etc/puppetlabs/puppet/ssl'
    $certname = $::trusted['certname']
    
    file { $q_pki_dir:
        ensure => directory,
        owner  => $user,
        group  => $group,
        mode   => '0700',
    } ->
    file { $dst_dir:
        ensure => directory,
        owner  => $user,
        group  => $group,
        mode   => '0700',
    } ->
    file { "${dst_dir}/ca.crt":
        mode   => '0600',
        owner  => $user,
        group  => $group,
        source => "${puppet_ssl_dir}/certs/ca.pem",
    } ->
    file { "${dst_dir}/crl.crt":
        mode   => '0600',
        owner  => $user,
        group  => $group,
        source => "${puppet_ssl_dir}/crl.pem",
    }
    
    if $copy_key {
        file { "${dst_dir}/local.key":
            mode    => '0600',
            owner   => $user,
            group   => $group,
            source  => "${puppet_ssl_dir}/private_keys/${certname}.pem",
            require => File[$dst_dir],
        } ->
        file { "${dst_dir}/local.crt":
            mode   => '0600',
            owner  => $user,
            group  => $group,
            source => "${puppet_ssl_dir}/certs/${certname}.pem",
        }
    }
}