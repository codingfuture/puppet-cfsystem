#
# Copyright 2016-2019 (c) Andrey Galkin
#


# Please see README
class cfsystem::custombin {
    include cfsystem

    $root_dir = '/opt/codingfuture'
    $bin_dir = "${root_dir}/bin"

    file { $root_dir:
        ensure => directory,
        mode   => '0755',
    }
    -> file { $bin_dir:
        ensure  => directory,
        mode    => '0755',
        purge   => true,
        recurse => true,
    }
    -> file { '/etc/profile.d':
        ensure  => directory,
        mode    => '0755',
        purge   => true,
        recurse => true,
    }
    -> file { '/etc/profile.d/bash_completion.sh':
        ensure  => present,
        mode    => '0644',
        replace => false,
    }

    # Kernel version checker
    #---
    $cf_kernel_version_check = "${bin_dir}/cf_kernel_version_check"
    file { $cf_kernel_version_check:
        mode    => '0555',
        content => file('cfsystem/cf_kernel_version_check'),
    }
    -> cron { $cf_kernel_version_check:
        command => $cf_kernel_version_check,
        hour    => 12,
        minute  => 0,
    }

    # Auto-scheduler
    #---
    $cf_auto_block_scheduler = "${bin_dir}/cf_auto_block_scheduler"

    file { $cf_auto_block_scheduler:
        mode    => '0500',
        content => epp('cfsystem/cf_auto_block_scheduler.epp'),
    }

    # PGP key updater
    #---
    $cf_apt_key_updater = "${bin_dir}/cf_apt_key_updater"

    file { $cf_apt_key_updater:
        mode    => '0500',
        content => epp('cfsystem/cf_apt_key_updater.epp', {
            http_proxy => $cfsystem::http_proxy,
            key_server => $cfsystem::key_server,
        })
    }

    # NTP date
    #---
    $cf_ntpdate = "${bin_dir}/cf_ntpdate"

    file { $cf_ntpdate:
        mode    => '0500',
        content => epp('cfsystem/cf_ntpdate.epp', {
            servers => any2array($cfsystem::ntp_servers)
        }),
    }

    # Wait socket tools (useful for systemd ExecStartPost)
    #---
    $cf_wait_socket = "${bin_dir}/cf_wait_socket"

    file { $cf_wait_socket:
        mode    => '0555',
        content => file('cfsystem/cf_wait_socket.sh'),
    }
}
