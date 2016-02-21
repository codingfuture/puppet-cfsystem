# Change Log

All notable changes to this project will be documented in this file. This
project adheres to [Semantic Versioning](http://semver.org/).

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

[0.9.4]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.4
[0.9.3]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.3
[0.9.2]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.2
[0.9.1]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.1
[0.9.0]: https://github.com/codingfuture/puppet-cfsystem/releases/tag/v0.9.0

