
class cfsystem::haproxy(
    $disable_standard = true
) {
    $package_name = 'haproxy'
    
    if $::facts['lsbdistcodename'] == 'jessie' {
        apt::pin{ $package_name:
            codename => 'jessie-backports',
            packages => $package_name,
            priority => $cfsystem::apt_pin + 1,
        } ->
        package{ $package_name:
            ensure => latest,
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