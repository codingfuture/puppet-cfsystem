#
# Copyright 2016-2019 (c) Andrey Galkin
#


# Please see README
class cfsystem::hwm::dell::aptrepo {
    assert_private();

    $lsbdistcodename = $::facts['lsbdistcodename']
    $release = $::facts['operatingsystem'] ? {
        'Debian' => (versioncmp($::facts['operatingsystemrelease'], '9') >= 0) ? {
            true    => 'jessie',
            default => $lsbdistcodename
        },
        'Ubuntu' => (versioncmp($::facts['operatingsystemrelease'], '18.04') >= 0) ? {
            true    => 'bionic',
            default => $lsbdistcodename
        },
        default  => $lsbdistcodename
    }

    apt::key { 'dell':
        id      => '42550ABD1E80D7C1BC0BAD851285491434D8786F',
        content => '
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1

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
SNnmxzdpR6pYJGbEDdFyZFe5xHRWSlrC3WTbzg==
=WBHf
-----END PGP PUBLIC KEY BLOCK-----
',
    }

    apt::source { 'dell':
        location => "${cfsystem::hwm::dell::community_repo}/ubuntu/",
        release  => $release,
        repos    => 'openmanage',
        pin      => $cfsystem::apt_pin + 1,
        require  => Apt::Key['dell'],
    }

}
