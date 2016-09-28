
class cfsystem::hierapool (
    Optional[String] $location = undef,
    Optional[String] $pool = undef
) {
    include stdlib
    assert_private();
    
    if $location {
        file {'/etc/cflocation':
            group   => root,
            owner   => root,
            mode    => '0400',
            content => $location,
        }
    }
    if $pool {
        file {'/etc/cflocationpool':
            group   => root,
            owner   => root,
            mode    => '0400',
            content => $pool,
        }
    }

}