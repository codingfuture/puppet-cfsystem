
class cfsystem::debian (
    String $apt_url = 'http://httpredir.debian.org/debian',
    String $security_apt_url = 'http://security.debian.org/',
    String $release = $::facts['lsbdistcodename'],
) {
    include stdlib
    assert_private();
    
    class { 'cfsystem::debian::aptconfig': stage => 'setup' }
    
    include cfsystem::debian::packages
}