
class cfsystem::sysctl (
    Integer $vm_swappiness = 1 # 0-100%
) {
    include stdlib
    assert_private();
    
    sysctl{ 'vm.swappiness': value => $vm_swappiness }
}