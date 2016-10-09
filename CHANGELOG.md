# Change Log

All notable changes to this project will be documented in this file. This
project adheres to [Semantic Versioning](http://semver.org/).

## [0.9.29]
- New internal API for systemd file cleanup

## [0.9.28]
- Added `cfsystem::ntpd_type` to support ntp(default), openntpd and chrony
- Changed default ntp.conf to use "tinker panic 0" to force time sync
- Precised parameter types

## [0.9.27]
- Added global wget configuration with http_proxy/https_proxy
- Fixed BlockIOWeight and CPUShares default calculations
- Added more advanced apt-cacher-ng configuration support
- Added maxmind GeoIP database support for apt-cacher-ng
- Changed to disable puppet agent by default
- Added atomic file write dry_run support (internal API)
- Fixed to strip /etc/cflocation & /etc/cflocationpool in case of manual changes
- Disabled show diff on cfsystem::puppetpki

## [0.9.26]
- Fixed previous broken release for cases with no HTTP proxy configured
- Enforced parameter types

## [0.9.25]
- Added more puppet keys to auto-update
- Added generic helper `cf_apt_key_updater`
- Added `cf_kernel_version_check` on every deploy

## [0.9.24]
- Added internal `cfsystem_info` helper to store arbitrary info in `cfsystem.json`

## [0.9.23]
- Fixed to install libssl1.0.0 dep for latest HAProxy @ Jessie

## [0.9.22]
- Fixed case of PuppetLabs PGP key auto-update without proxy

## [0.9.21]
- Fixed wrong version of PuppetLabs PGP key auto-update getting in release

## [0.9.20]
- Implemented auto-update of PuppetLabs PGP key

## [0.9.19]
- Fixed to enable services during creation in Ruby framework

## [0.9.18]
- Minor fix of private Ruby infrastructure

## [0.9.17]
- Changed parser helper `cf_genpass` and `cf_genport` to use facts and act like client-side counterpart
- Added `cf_genport` helper integrated with facts
- Improved logic of CfSystem.genPort()
- Added `cfsystem::haproxy` to setup packages
- Added custom `$pki_dir` support to `cfsystem::puppetpki`
- Fixed to make sort cfsystem.json sections are sorted as well
- Fixed not to fail all resources, if some resource save handler fails in cfsystem.json
- Added wrappers around `puppetdbquery` module
- Fixed to support static catalog (no puppet:// source)

## [0.9.16]
- Added control parameter for mcollective service
- Improved security of .env files - only owner can read
- Implemented stable sorting of cfsystem.json section content
- Fixed exim4 provisioning deps & misc.

## [0.9.15]
- Fixed to correctly support Ubuntu Xenial
    - Added disabling of IPv6 in APT
    - Added disabling of not yet supported backports
    - Changed to use fixed mirror by default

## [0.9.14]
- Disabled scheduled agent runs for safety purposes
- Implemented framework support for systemd slices

## [0.9.13]
- Fixed to pass strict mode checking
- Implemented automatic memory distribution with incremental part definitions per service
- Added cfsystem::puppetpki type to copy puppet PKI for local user
- Added strace to list of standard tools
- Updated deps to latest versions

## [0.9.12]
- Workaround to use jessie for stretch for PuppetLabs APT repo
- Changed back to use xenial for appeared PuppetLabs APT repo
- Added support for next Ubuntu 16.10 (yakkety)
- Implemented experimental framework for:
    * weight based memory distribution
    * resource configuration management
- Implemented a new feature cfsystem::dotenv to manange ~/.env config
- Moved block scheduler logic from rc.local to cf_auto_block_scheduler script

## [0.9.11]
- Added missing apt-listchanges installation
- Added a workaround to install wily packages for xenial until PuppetLabs release those
- Added special '_apt' user support for stretch/xenial
- Updated to use current Debian/Ubuntu release (fact) as the default for APT

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

[0.9.29]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.29
[0.9.28]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.28
[0.9.27]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.27
[0.9.26]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.26
[0.9.25]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.25
[0.9.24]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.24
[0.9.23]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.23
[0.9.22]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.22
[0.9.21]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.21
[0.9.20]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.20
[0.9.19]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.19
[0.9.18]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.18
[0.9.17]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.17
[0.9.16]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.16
[0.9.15]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.15
[0.9.14]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.14
[0.9.13]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.13
[0.9.12]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.12
[0.9.11]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.11
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

