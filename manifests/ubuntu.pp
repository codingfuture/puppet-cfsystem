
class cfsystem::ubuntu (
    #$apt_url = 'mirror://mirrors.ubuntu.com/mirrors.txt',
    $apt_url = 'http://ftp.halifax.rwth-aachen.de/ubuntu/',
    $release = $::facts['lsbdistcodename'],
    $disable_ipv6 = true,
) {
    include stdlib
    assert_private();
    
    class { 'cfsystem::ubuntu::aptconfig': stage => 'setup' }

    include cfsystem::debian::packages
}