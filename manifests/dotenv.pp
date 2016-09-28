
define cfsystem::dotenv(
    String $user,
    String $variable,
    String $value,
    String $env_file = '.env',
) {
    $home = getparam(User[$user], 'home')
    
    if !$home or $home == '' {
        fail("User ${user} must be defined with explicit 'home' parameter")
    }
    
    $dotenv_file = "${home}/${env_file}"
    
    ensure_resource('file', $dotenv_file, {
        ensure  => present,
        owner   => $user,
        mode    => '0400',
        content => '',
        replace => false,
    })
    
    file_line { "${dotenv_file}/${variable}":
        ensure   => present,
        path     => $dotenv_file,
        line     => "${variable}=\"${value}\"",
        match    => "^${variable}",
        replace  => true,
        multiple => true,
        require  => File[$dotenv_file],
    }
}