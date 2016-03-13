# Change Log

All notable changes to this project will be documented in this file. This
project adheres to [Semantic Versioning](http://semver.org/).

## [0.9.10]
- Fixed cf_kernel_version_check to work on Ubuntu with /proc/version_signature

## [0.9.9]
- Implemented cron job for outdated kernel version detection (reboot reminder)
- Added generic /opt/codingfuture/bin folder for all installed scripts
- Moved to generic bin dir and renamed exim helper tools
    * cf_send_test_email
    * cf_clear_email_queue
    * cf_clear_frozen_emails

## [0.9.8]
- Added generic infrastructure for Debconf support (cfsystem::debian::debconf)
- Added support for default system locale
- Added installation of all locales
- Updated Timezone configuration to properly utilize Debconf on Debian & Ubuntu
- Added APT pinning support with forced downgrades by default
- Fixed apt-cacher-ng to allow root user http/https connections during dpkg processing

## [0.9.7]

- Fixed use_srv_records puppet setting to depend on correct parameter
- Fixed to unconditionally install puppet-agent package

## [0.9.6]

- Fixed issue of ca_server not being properly set in some cases

## [0.9.5]

- Changed to force 'default' value for cf_location and cf_location_pool, unless set.
  That's required to minimize issues due to empty interpolation in Hiera paths.
- Moved sudo and openssh-server installation to cfauth module
- Reorganized internal manifests
- Added puppet agent configuration parameters, including CA server, use DNS SRV records,
  and puppet environment
- Dropped off external timezone module dependency and re-implemented internally
- Changed to use PuppetLabs approved augeas sysctl module
- Dropped of external openntpd module dependency and re-implementd internally due
  to original implementation dependency on module_data module which breaks Puppet 4.
- OpenNTPd is using "servers" instead of "server" configuration option now.


## [0.9.4]

* Removed inittab processing for Xen PV guests as they should use systemd

## [0.9.3]

* Force to re-execute sysctl conf in rc.local
* Added custom I/O scheduler support
* Forced noop scheduler for SSD and virtual devices
* Added custom rc.local commands support
* Added 'cf_virt_detect' which has output of systemd-detect-virt
* Fixed issue of apt-cacher-ng bootstrap when APT config depends on 
   not yet installed proxy
* Fixed to use xen PV console on xen hosts

## [0.9.2]

- Added hiera.yaml version 4 support

## [0.9.1]

- Added APT purge and update control through cfsystem parameters

## [0.9.0]

Initial release

[0.9.10]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.10
[0.9.9]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.9
[0.9.8]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.8
[0.9.7]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.7
[0.9.6]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.6
[0.9.5]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.5
[0.9.4]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.4
[0.9.3]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.3
[0.9.2]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.2
[0.9.1]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.1
[0.9.0]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.0

