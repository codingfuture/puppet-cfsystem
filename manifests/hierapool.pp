
class cfsystem::hierapool (
    Optional[String[1]] $location = undef,
    Optional[String[1]] $pool = undef
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