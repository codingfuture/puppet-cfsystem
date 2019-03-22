#
# Copyright 2016-2019 (c) Andrey Galkin
#


# Please see README
define cfsystem::dotenv(
    String[1] $user,
    String[1] $variable,
    Variant[String, Numeric] $value,
    String[1] $env_file = '.env',
) {
    $home = getparam(User[$user], 'home')

    if !$home or $home == '' {
        fail("User ${user} must be defined with explicit 'home' parameter")
    }

    if $env_file[0] == '/' {
        $dotenv_file = $env_file
    } else {
        $dotenv_file = "${home}/${env_file}"
    }

    if !defined(File[$dotenv_file]) {
        # NOTE: do not use ensure_resource
        file { $dotenv_file:
            ensure  => present,
            owner   => $user,
            mode    => '0400',
            content => '',
            replace => false,
        }
    }

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
