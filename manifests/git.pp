
class cfsystem::git {
    include stdlib
    assert_private();

    include ::git
    $certname = $::trusted['certname']
    git::config { 'user.name':
        value => 'Root',
        require => Package['git'],
    }
    git::config { 'user.email':
        value => "root@${certname}",
        require => Package['git'],
    }
}
