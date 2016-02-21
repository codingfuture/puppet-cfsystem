
class cfsystem::debian (
    $apt_url = 'http://httpredir.debian.org/debian',
    $security_apt_url = 'http://security.debian.org/',
    $release = 'jessie',
) {
    include stdlib
    assert_private();
    
    class { 'cfsystem::debian::aptconfig': stage => 'setup' }
    
    include cfsystem::debian::packages
}