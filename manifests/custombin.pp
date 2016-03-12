
class cfsystem::custombin {
    $root_dir = '/opt/codingfuture'
    $bin_dir = "${root_dir}/bin"
    
    file { $root_dir:
        ensure => directory,
        mode   => '0755',
    } ->
    file { $bin_dir:
        ensure => directory,
        mode   => '0755',
    } ->
    file { '/etc/profile.d/codingfuture.sh':
        content => "
if ! echo \$PATH | grep -q ${bin_dir}; then
  export PATH=\"\$PATH:${bin_dir}\"
fi
"
    } ->
    file { '/etc/profile.d/codingfuture.csh':
        content => "
set path = (\$path ${bin_dir})
"
    }
    
    $cf_kernel_version_check = "${bin_dir}/cf_kernel_version_check"
    file { $cf_kernel_version_check:
        mode   => '755',
        source => 'puppet:///modules/cfsystem/cf_kernel_version_check',
    } ->    
    cron { $cf_kernel_version_check:
        command => $cf_kernel_version_check,
        hour   => 12,
        minute => 0,
    }
}