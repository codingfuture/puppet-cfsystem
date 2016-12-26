
# Please see README
class cfsystem::debian (
    String[1] $apt_url = 'http://httpredir.debian.org/debian',
    String[1] $security_apt_url = 'http://security.debian.org/',
    String[1] $release = $::facts['lsbdistcodename'],
) {
    include stdlib
    assert_private();

    class { 'cfsystem::debian::aptconfig': stage => 'setup' }

    include cfsystem::debian::packages
}