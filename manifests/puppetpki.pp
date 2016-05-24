
define cfsystem::puppetpki(
    $user = $title,
    $copy_key = true,
) {
    $home = getparam(User[$user], 'home')
    $group = pick(getparam(User[$user], 'group'), $user)
    
    if !$home or $home == '' {
        fail("User ${user} must be defined with explicit 'home' parameter")
    }
    
    $pki_dir = "${home}/pki"
    $dst_dir = "${pki_dir}/puppet"
    $puppet_ssl_dir = '/etc/puppetlabs/puppet/ssl'
    $certname = $::trusted['certname']
    
    file { $pki_dir:
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
            group   => $group,
            source => "${puppet_ssl_dir}/certs/${certname}.pem",
        }
    }
}