#
# Copyright 2016-2019 (c) Andrey Galkin
#


# Please see README
class cfsystem::sysctl (
    Integer[0,100] $vm_swappiness = 1, # 0-100%
    Integer[0] $vm_mmax_map_count = 262144,
) {
    include stdlib
    assert_private();

    sysctl{ 'vm.swappiness': value => $vm_swappiness }
    sysctl{ 'vm.max_map_count': value => $vm_mmax_map_count }
}
