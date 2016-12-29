#
# Copyright 2016 (c) Andrey Galkin
#


# Please see README
class cfsystem::hwm(
    Enum['none', 'auto', 'generic', 'dell', 'smc'] $type = 'auto',
) {
    assert_private();

    if $type != 'auto' {
        $actual_type = $type
    } else {
        $manufacturer = try_get_value($::facts, 'dmi/manufacturer', '')

        if ($manufacturer =~ /Dell/ and
            try_get_value($::facts, 'dmi/product/name', '') =~ /PowerEdge/
        ) {
            $actual_type = 'dell'
        } elsif $manufacturer =~ 'Supermicro' {
            $actual_type = 'smc'
        } else {
            $actual_type = 'none'
        }
    }

    if $actual_type != 'none' {
        include "cfsystem::hwm::${actual_type}"

        ensure_packages([
            'openipmi',
            'ipmitool',
        ])

        ensure_resource('service', 'ipmievd', {
            ensure  => running,
            enable  => true,
            require => Package['ipmitool'],
        })
    }
}
