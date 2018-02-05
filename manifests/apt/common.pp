#
# Copyright 2017-2018 (c) Andrey Galkin
#

# Please see README
class cfsystem::apt::common(
    String[1]
        $puppet_release,
    Boolean
        $force_ipv4 = false,
) {
    assert_private()

    apt::conf { 'local-thin':
        content => [
            'APT::Install-Recommends "0";',
            'APT::Install-Suggests "0";',
            'Acquire::Languages "none";',
            ''
        ].join("\n"),
    }

    if $force_ipv4 {
        apt::conf { 'force-ipv4':
            content => [
                'Acquire::ForceIPv4 "true";',
                ''
            ].join("\n"),
        }
    }

    stage { 'cf-apt-setup':
        require => Stage['setup'],
        before  => Stage['main'],
    }

    class { 'cfsystem::apt::update':
        stage => 'cf-apt-setup',
    }

    class { 'cfsystem::apt::puppetlabs':
        release => $puppet_release,
        stage   => 'cf-apt-setup',
    }
}
