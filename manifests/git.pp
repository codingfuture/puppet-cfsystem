
class cfsystem::git {
    include stdlib
    assert_private();

    include ::git
    $certname = $::trusted['certname']
    git::config { 'user.name': value => 'Root' }
    git::config { 'user.email': value => "root@${certname}" }
}
