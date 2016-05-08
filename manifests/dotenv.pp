
define cfsystem::dotenv(
    $user,
    $variable,
    $value,
    $env_file = '.env',
) {
    $home = getparam(User[$user], 'home')
    
    if !$home or $home == '' {
        fail("User ${user} must be defined with explicit 'home' parameter")
    }
    
    $dotenv_file = "${home}/${env_file}"
    
    if !defined(File[$dotenv_file]) {
        file { $dotenv_file:
            ensure => present,
            content => '',
            replace => false,
        }
    }
    
    file_line { "${dotenv_file}/${variable}":
        ensure => present,
        path => $dotenv_file,
        line => "${variable}=\"${value}\"",
        match => "^${variable}",
        replace => true,
        multiple => true,
        require => File[$dotenv_file],
    }
}