# Change Log

All notable changes to this project will be documented in this file. This
project adheres to [Semantic Versioning](http://semver.org/).

## 1.3.0 (2019-04-14)
- FIXED: forced secrets to override persistent values
- FIXED: atomicWrite to obey ownership & mode when content is the same
- FIXED: cfsystem_timer exceptions in some configurations
- CHANGED: to prune /opt/codingfuture/bin
- CHANGED: Ubuntu instance to remove update-motd package
- CHANGED: got rid of historical cf-apt-update workaround
- NEW: 'silent' atomic file write API for temporary cases

## 1.2.0 (2018-12-09)
- CHANGED: updated for Ubuntu 18.04 Bionic support
- CHANGED: to use cfhttp service in firewall config
- CHANGED: enabled cgroup-v2 for kernels 4.5+
- NEW: cfsystem::add_handy_tools to control additional package setup
- NEW: FreeIPA NTP support
- NEW: cfsystem_service type
- NEW: cfsystem_timer type

## 1.1.0 (2018-05-02)
- NEW: cfsystem::metric type as a sort of IoC to integrate cfmetrics
- NEW: Copy-on-Write reserve feature for service definition (overcommit)
- NEW: cfsystem::add_group functions

## 1.0.2 (2018-04-29)
- CHANGED: to allow zero min/max memory requirements
- NEW: cfsystem::pip class for latest pip setup in /usr/local

## 1.0.1 (2018-04-13)
- FIXED: Metaspace JVM parameter detection with JRE 1.8.0_162+
- FIXED: updated exim4 config template

## 0.12.9 (2018-03-24)
- NEW: generic cfsystem::sshdir with custom configuration extension support

## 0.12.8 (2018-03-19)
- NEW: cf_notify as replacement for standard notify to avoid its refresh side effects
- NEW: added tshark package for standard installation

## 0.12.7 (2018-03-15)
- CHANGED: to always prefer PSON serialization to avoid retries
- CHANGED: moved syslog related stuff solely to cflogsink

## [0.12.6](https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.12.6)
- CHANGED: improved APT cache, Email & NTP service security with ipset:localnet
- FIXED: internal API to allow custom EnvironmentFile for systemd unit
- NEW: cfsystem::location variable
- NEW: cfsystem::netsyslog functionality
- NEW: cfsystem::hdsyslog functionality
- NEW: CfSystem.makeVersion now supports directory traversal
- NEW: show amount of unused RAM in memory distribution

## [0.12.5](https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.12.5)
- CHANGED: to mask instead of just disable agent/mcollective, if required

## [0.12.4](https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.12.4)
- FIXED: support systemd 236+ timesyncd setup

## [0.12.3](https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.12.3)
- CHANGED: to use systemd-timesyncd by default
- NEW: systemd-timesyncd support
- NEW: cfsystem::sysctl::vm_mmax_map_count
- NEW: custom systemd services to use service name for syslog tagging

## [0.12.2](https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.12.2)
- FIXED: minor ntp.conf configuration issues

## [0.12.1](https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.12.1)
- CHANGED: cfsystem::service_face to default to cfnetwork::service_face
- FIXED/CHANGED: ntpd configuration to use "server" instead of "pool"

## [0.12.0](https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.12.0)
- CHANGED: to use Puppet 5 by default
- FIXED: Puppet 5 runtime issues
- FIXED: cf_auto_block_scheduler to work with stricter "test"

## [0.11.9](https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.11.9)
- NEW: cfsystem::clusterssh adds also public key file for convenience

## [0.11.8](https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.11.8)
- FIXED: clusterssh / PuppetX::CfSystem::Util.genKeyCommon to force new keys
    on secondary instances when old one is already set

## [0.11.7](https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.11.7)
- FIXED: kernel version check to filter out only installed versions

## [0.11.6](https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.11.6)
- FIXED: kernel version check to use natural sorting after version extraction

## [0.11.5](https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.11.5)
- FIXED: kernel version check to use natural sorting

## [0.11.4](https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.11.4)
- CHANGED: to use now available Stretch repository

## [0.11.3](https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.11.3)
- CHANGED: LimitMEMLOCK is set to "infinity" instead of MemoryMax size, if requested
- NEW: absolute cfsystem::dotenv filename support
- NEW: string support to systemd memory limits (internal API)

## [0.11.2](https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.11.2)
- FIXED: to allow execute cf_wait_socket helper by any user
- CHANGED: to use http://deb.debian.org/debian as default for Debian
- CHANGED: to use $apt_backports_pin = 1001 by default for old system
- CHANGED: updated to APT module >= 4.1
- NEW: Puppet 5.x support
- NEW: Ubuntu Zesty support
- NEW: cfsystem::pretty_json

## [0.11.1]
- Changed ntpdate cron to mail output only if |time offset| >= 1

## [0.11.0]
- Minor fix for HAProxy setup @ jessie
- Fixed to also pin libssl-dev @ jessie
- Fixed to properly create slice extension
- Updated to new 'cfnetwork::bind_address' API
- Added cf_ntpdate wrapper & cron job
- Changed not to run apt-update only when require, but not daily
    - Solves cases of failed APT update during catalog deploy
    - Added second attempt on failure
- Fixed a long standing issues with "exists" in ensure processing
- Refactor persistent handling and added internal cfsystem_persist type
    to minimize dependency on facts
- Implemented generic cfsystem::clusterssh to aid cluster deployment
    with tradeoff for security
- Changed NTPd "server" to "pool" directive
- Fixed long standing issues with mutable fact processing
- Added cf_wait_sock utility & refactored internal API
- Added /etc/profile.d management through cfsystem::binpath
- Added cfsystem::binpath to sudo search_path
- Fixed old problem of not processed providers on first run
- Fixed to stop service prior to cleanup
- Dropped dependency on dalen-puppetdbquery in favor of native puppetdb_query
- Removed old cf_query_*() API
- Added cfsystem::query() API with catalog-specific caching
- Removed deprecated calls to try_get_value()
- Refactored and exposes 'cfsystem::gen_*()' API

## [0.10.1]
- Added installation of libpam-systemd to workaround sshd session issues
- Fixed to properly disable puppet/mcollective/pxp-agent
- Fixed Stretch apt-key issues
- Fixed to support Debian "testing" target
- Converted to support Debian/Ubuntu based on LSB versions, but not codenames
- Switched default keyserver to keyserver.ubuntu.com due to issues with pgp.mit.edu
- Fixed BASE_PORT redifinition warnings
- Fixed not to add backports for testing
- puppet_release apt-key looping update issues
- Added aptitude, psmisc and dnsutils to the list of essential packages
- Added "Debian Old" repos for testing to help migration of external repos
- Fixed puppetlabs apt::key update issues & minor refactoring
- Changed to use puppetlabs-release-pc1 as the only up-to-date source of
    PuppetLabs signing keys
- Updated to cfnetwork:0.10.1, cfauth:0.10.1

## [0.10.0]
- Fixed to allow ntp connection to localhost for internal purposes
- Fixed to make sure `systemd` is init
- Updated to `cfnetwork` 0.10.0 API changes
- Updated CF deps to v0.10.x

## [0.9.35]
- Fixed another minor typo in hwm::smc type

## [0.9.34]
- Fixed syntax error in HWM generic type
- Automatic newer puppet-lint fixes
- Fixed puppet-lint and metadata-json-lint warnings

## [0.9.33]
- Added experimental support for HardWare Management
 > Added generic IPMI support
 > Added Dell APT report + OpenManage installation
- Fixed minor issue with undefined variables

## [0.9.32]
- Added `cfsystem::randomfeed` with `haveged`

## [0.9.31]
- Fixed to use proper firewall user names for NTP daemon choices
- Added iotop package to installation

## [0.9.30]
- Bug fixes for recent internal API

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

[0.11.1]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.11.1
[0.11.0]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.11.0
[0.10.1]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.10.1
[0.10.0]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.10.0
[0.9.35]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.35
[0.9.34]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.34
[0.9.33]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.33
[0.9.32]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.32
[0.9.31]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.31
[0.9.30]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.30
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

