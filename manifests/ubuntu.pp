
class cfsystem::ubuntu (
    $apt_url = 'mirror://mirrors.ubuntu.com/mirrors.txt',
    $release = $::facts['lsbdistcodename'],
) {
    include stdlib
    assert_private();
    
    class { 'cfsystem::ubuntu::aptconfig': stage => 'setup' }

    include cfsystem::debian::packages
}