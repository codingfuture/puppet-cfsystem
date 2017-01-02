#
# Copyright 2016-2017 (c) Andrey Galkin
#


# Please see README
class cfsystem::sysctl (
    Integer[0,100] $vm_swappiness = 1 # 0-100%
) {
    include stdlib
    assert_private();

    sysctl{ 'vm.swappiness': value => $vm_swappiness }
}
