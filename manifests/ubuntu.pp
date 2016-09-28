
class cfsystem::ubuntu (
    #$apt_url = 'mirror://mirrors.ubuntu.com/mirrors.txt',
    String $apt_url = 'http://ftp.halifax.rwth-aachen.de/ubuntu/',
    String $release = $::facts['lsbdistcodename'],
    Boolean $disable_ipv6 = true,
) {
    include stdlib
    assert_private();
    
    class { 'cfsystem::ubuntu::aptconfig': stage => 'setup' }

    include cfsystem::debian::packages
}