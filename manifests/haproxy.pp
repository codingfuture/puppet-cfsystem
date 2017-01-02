#
# Copyright 2016-2017 (c) Andrey Galkin
#


# Please see README
class cfsystem::haproxy(
    Boolean $disable_standard = true
) {
    $package_name = 'haproxy'

    if $::facts['lsbdistcodename'] == 'jessie' {
        $libssl_name = 'libssl1.0.0'

        # A workaround for provisioning of new systems
        apt::pin{ $libssl_name:
            codename => 'jessie-backports',
            packages => $libssl_name,
            priority => $cfsystem::apt_pin + 1,
        }
        ensure_resource('package', $libssl_name, {
            ensure  => latest,
            require => Apt::Pin[$libssl_name],
        })

        apt::pin{ $package_name:
            codename => 'jessie-backports',
            packages => $package_name,
            priority => $cfsystem::apt_pin + 1,
        } ->
        package{ $package_name:
            ensure  => latest,
            require => Package['libssl1.0.0']
        }

    } else {
        package{ $package_name: }
    }

    if $disable_standard {
        service { 'haproxy':
            ensure => stopped,
            enable => false,
        }
    }
}
