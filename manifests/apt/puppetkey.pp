#
# Copyright 2016-2018 (c) Andrey Galkin
#


# Please see README
class cfsystem::apt::puppetkey(
    $key_ids = {
        'info'    => '47B320EB4C7C375AA9DAE1A01054B7A24BD6EC30',
        'release' => '6F6B15509CF8E59E6E469F327F438280EF8D349F',
        'nightly' => '8735F5AF62A99A628EC13377B8F999C007BB6C57',
    }
) {
    assert_private()

    $key_ids.each |$key_name, $key_id| {
        cfsystem::apt::key { "puppetlabs_${key_name}":
            id      => $key_id,
        }
    }
}
