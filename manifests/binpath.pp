#
# Copyright 2017-2018 (c) Andrey Galkin
#

define cfsystem::binpath(
    String[1] $bin_dir,
) {
    file { "/etc/profile.d/${title}.sh":
        content => "
if ! echo \$PATH | grep -q ${bin_dir}; then
  export PATH=\"\$PATH:${bin_dir}\"
fi
"
    }
    -> file { "/etc/profile.d/${title}.csh":
        content => "
set path = (\$path ${bin_dir})
"
    }
    -> cfsystem_secure_path { $title:
        ensure => present,
        path   => $bin_dir,
    }
}
