# cfsystem

## Description

Configure a bare minimal production system regardless of its purpose. It depends on
more specific [cfnetwork][], [cfauth][] and [cffirehol][] modules.

What it does:

* Whatever [cfnetwork][] does
* Whatever [cfauth][] does
* Whatever [cffirehol][] does
* Setups APT for Debian and Ubuntu
* Setups timezone
* Setups hostname based on certname
* Adds firewall rules as required
* Setups special location/pool facts for hiera lookup (see cfsystem::hierapool below)
* Setups email system
* Setups NTP
* Installs many handy system tools which almost any admin would expect
* Force noop scheduler on SSDs and virtual devices (in guests)
* Force custom I/O scheduler for real spinning HDDs (deadline by default)
* Add custom rc.local commands, if needed


## Technical Support

* [Example configuration](https://github.com/codingfuture/puppet-test)
* Commercial support: [support@codingfuture.net](mailto:support@codingfuture.net)

## Setup

If r10k is used until [RK-3](https://tickets.puppetlabs.com/browse/RK-3) is solved, make
sure to have the following lines in Puppetfile:

```ruby
mod 'puppetlabs/stdlib', '4.11.0'
mod 'puppetlabs/apt', '2.2.1'
mod 'puppetlabs/git', '0.4.0'
mod 'saz/timezone', '3.3.0'
mod 'fiddyspence/sysctl', '1.1.0'
mod 'codingfuture/cfnetwork'
mod 'codingfuture/cfauth'
# make sure you check dependencies of dependencies too.
```

## Examples

Please check [codingufuture/puppet-test](https://github.com/codingfuture/puppet-test) for
example of a complete infrastructure configuration and Vagrant provisioning.

## Implicitly created resources

```yaml
cfnetwork::describe_services:
    puppet:
        server: 'tcp/8140'
    smtp:
        server: 'tcp/25'
    cfsmtp:
        server:
            - 'tcp/25'  # smtp
            - 'tcp/465' # smtps
            - 'tcp/587' # submission
    # if $cfsystem::add_repo_cacher
    'apcng':
        server: 'tcp/3142'
    # if $cfsystem::repo_proxy
    'aptproxy':
        server: "tcp/${proxy_port}"
cfnetwork::service_ports:
    # foreach $cfsystem::email::listen_ifaces
    "${listen_ifaces}:smtp:cfsystem": {}
    'local:smtp:cfsystem': {}
    # if $cfsystem::add_ntp_server
    "${cfsystem::service_face}:ntp": {}
    # if $cfsystem::add_repo_cacher
    "${cfsystem::service_face}:apcng:cfsystem": {}
    # if ${cfsystem::service_face} not in ['any', 'local']
    'local:apcng:cfsystem': {}
cfnetwork::client_ports:
    'any:puppet:cfsystem':
        user: 'root'
    'local:smtp:cfsystem': {}
    # if $smarthost = undef then dst filtering is disabled
    'any:cfsmtp:cfsystem':
        user => ['root', 'Debian-exim'],
        dst  => $smarthost
    'any:ntp:cfsystem':
        user => ['root', 'ntpd'],
    # if $cfsystem::add_repo_cacher
    'any:http:apcng':
        user: 'apt-cacher-ng'
    # if $cfsystem::add_repo_cacher
    'any:https:apcng':
        user: 'apt-cacher-ng'
    # if $cfsystem::repo_proxy
    'any:aptproxy:cfsystem':
        dst: $proxy_host
        user: 'root'
    # if not $cfsystem::repo_proxy
    'any:http:cfsystem':
        user: 'root'
    # if not $cfsystem::repo_proxy
    'any:https:cfsystem':
        user: 'root'
```

## Class parameters

## `cfsystem`

* `allow_nfs = false` - purge RPC packages unless true
* `admin_email = undef` - email address to use for `root` and as the default sink
* `repo_proxy = undef` - if set, use the config as HTTP/HTTPS proxy for package retrieval.
    * `host` - IP or hostname
    * `port` - TCP port
* `add_repo_cacher = false` - if true, install apt-cacher-ng and accept clients on `$service_face`
* `service_face = 'any'` - interface to accept client for NTP and HTTP proxy, if enabled separately
* `ntp_servers = [ 'pool.ntp.org' ]` - upstream NTP server
* `add_ntp_server = false` - if true, accept NTP service clients on `$service_face`
* `timezone = 'Etc/UTC'` - setup system timezone
* `apt_purge` - passed to apt::purge, purge all sources and preferences by default
* `apt_update` - passed to apt::update, update daily with 300 second timeout by default
* `real_hdd_scheduler` - default scheduler for not SSD and not virtualized HDDs
* `rc_local` - list of additional commands to add to /etc/rc.local
    (SSD and virtual is always 'noop')

## `cfsystem::hierapool`

Automatically including by `cfsystem`. This values are useful in hiera.yaml configuration
to setup hierarchy based on location and tenant/server pool in it. Example:

```yaml
    ---
    :backends:
    - yaml
    :hierarchy:
    - "%{::trusted.domain}/%{::trusted.hostname}"
    - "%{::trusted.domain}"
    - "%{::cf_location}/%{::cf_location_pool}"
    - "%{::cf_location}"
    - common
    :merge_behavior: deeper
    :yaml:
    :datadir:
```

* `location = undef` - if set, saved into `/etc/cflocation`
* `pool = undef` - if set, aved into `/etc/cflocationpool`


## `cfsystem::email`

Setup email server for outgoing emails. **Please not that this configuration
is not intended to accept internet traffic.**

* `smarthost = undef` - if set, use as smarthost to relay outgoing emails through
* `smarthost_login = undef` - if set, use as login on smarthost
* `smarthost_password = undef` -  if set, use as password on smarthost (plain text)
* `relay_nets = <private subnets>` - allowed clients for SMTP relay, if relay is enabled
    with `$listen_ifaces`
* `listen_ifaces = undef` - list of interface (`cfnetwork::iface` names), besides `lo` to
    listen for SMTP client relay
* `disable_ipv6 = true` - if true, IPv6 supports gets disabled (most likely you
    need it disabled for SMTP)

## `cfsystem::sysctl`

Setup sysctl entries.

* `vm_swappiness = 1` - 0-100 (%) minimize swap activity by default

## `cfsystem::debian`

Debian-specific configuration.

* `apt_url = 'http://httpredir.debian.org/debian'` - APT base URL for Debian repos
* `security_apt_url = 'http://security.debian.org/'` - APT base URL for Debian security repo
* `release` = 'jessie' - Debian release name to configure

## `cfsystem::ubuntu`

Ubuntu-specific configuration.

* `apt_url = 'mirror://mirrors.ubuntu.com/mirrors.txt'` - APT base URL for Ubuntu repos
* `release = 'wily'` - Ubuntu release name to configure

[cfnetwork]: https://github.com/codingfuture/puppet-cfnetwork
[cfauth]: https://github.com/codingfuture/puppet-cfauth
[cffirehol]: https://github.com/codingfuture/puppet-cffirehol