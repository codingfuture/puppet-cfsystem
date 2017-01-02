#
# Copyright 2016-2017 (c) Andrey Galkin
#


# Please see README
class cfsystem::debian::puppetkey(
    $key_ids = {
        'info'    => '47B320EB4C7C375AA9DAE1A01054B7A24BD6EC30',
        'release' => '6F6B15509CF8E59E6E469F327F438280EF8D349F',
    }
) {
    assert_private()

    $key_ids.each |$key_name, $key_id| {
        cfsystem::debian::aptkey { "puppetlabs_${key_name}":
            id      => $key_id,
        }
    }
}
