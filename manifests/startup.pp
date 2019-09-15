#
# Copyright 2019 (c) Andrey Galkin
#


# Please see README
class cfsystem::startup {
    include stdlib
    assert_private();

    $startups = {
        '30'  => '/sbin/sysctl -p',
        '60'  => '/opt/puppetlabs/bin/puppet agent -t',
        '300' => '/opt/puppetlabs/bin/puppet agent -t',
    }

    $startups.each |$t, $c| {
        cfsystem_timer { "cftimer-startup${t}":
            ensure        => present,
            root_dir      => "/tmp",
            command       => $c,
            settings_tune => {
                'Timer' => {
                    'OnBootSec' => $t,
                }
            },
        }
    }
}
