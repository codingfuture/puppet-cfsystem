
# Please see README
class cfsystem::randomfeed(
    String[1] $type = 'haveged',
    Integer[1,4096] $threshold = 2048,
) {
    case $type {
        'haveged' : {
            package{ $type: } ->
            file {"/etc/default/${type}":
                content => [
                    "DAEMON_ARGS=\"-w ${threshold}\""
                ].join("\n"),
                notify  => Service[$type],
            } ->
            service { $type:
                ensure => running,
                enable => true,
            }
        }
        default : {
            fail("Unknown random feed type: ${type}")
        }
    }
}