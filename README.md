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
* Setup all locales and the default locale (configurable)
* Installs many handy system tools which almost any admin would expect
* Forces noop scheduler on SSDs and virtual devices (in guests)
* Forces custom I/O scheduler for real spinning HDDs (deadline by default)
* Adds custom rc.local commands, if needed
* Adds cron job to check if running kernel version matches the latest installed (reboot reminder)
* Auto-detect hardware nodes with IPMI
    * Install generic IPMI tools
    * Install Dell-specific tools
    * Other vendors - TODO
* Ruby framework for other cf* modules
* The following helper scripts are installed
    * `cf_clear_email_queue` - clear all emails in exim queue
    * `cf_clear_frozen_emails` - clear only frozen emails in exim queue
    * `cf_send_test_email` - send test email to admin address
    * `cf_kernel_version_check` - check if kernel version mismatch the latest installed one
    * `cf_auto_block_scheduler` - setup auto-detected I/O scheduler per block device
    * `cf_apt_key_updater <key_id>` - run GPG key re-import, if expired
* Public API for Puppet parser:
    * `cf_query_facts` - wrapper around `query_facts`
    * `cf_query_nodes` - wrapper around `query_nodes`
    * `cf_query_resources` - wrapper around `query_resources`
    * `cf_stable_sort(arg)` - deep sort of Hash/Array to avoid isomorphic configuration "change"


## Technical Support

* [Example configuration](https://github.com/codingfuture/puppet-test)
* Commercial support: [support@codingfuture.net](mailto:support@codingfuture.net)

## Setup

Please use [librarian-puppet](https://rubygems.org/gems/librarian-puppet/) or
[cfpuppetserver module](https://forge.puppetlabs.com/codingfuture/cfpuppetserver) to deal with dependencies.

There is a known r10k issue [RK-3](https://tickets.puppetlabs.com/browse/RK-3) which prevents
automatic dependencies of dependencies installation.

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

## `cfsystem` class

* `allow_nfs = false` - purge RPC packages unless true
* `admin_email = undef` - email address to use for `root` and as the default sink
* `repo_proxy = undef` - if set, use the config as HTTP/HTTPS proxy for package retrieval.
    * `host` - IP or hostname
    * `port` - TCP port
* `add_repo_cacher = false` - if true, install apt-cacher-ng and accept clients on `$service_face`
* `service_face = 'any'` - interface to accept client for NTP and HTTP proxy, if enabled separately
* `ntp_servers = [ 'pool.ntp.org' ]` - upstream NTP server
* `add_ntp_server = false` - if true, accept NTP service clients on `$service_face`
* `Enum['ntp', 'openntpd', 'chrony'] $ntpd_type = 'ntp'` - NTP implementation to use
* `timezone = 'Etc/UTC'` - setup system timezone
* `apt_purge` - passed to apt::purge, purge all sources and preferences by default
* `apt_update` - passed to apt::update, update daily with 300 second timeout by default
* `apt_pin = 1001` - default priority (>=1001 - force downgrades to make the system consistent)
* `apt_backports_pin = 600` - default priority (>=1001 - force downgrades to make the system consistent)
* `real_hdd_scheduler` - default scheduler for not SSD and not virtualized HDDs
* `rc_local` - list of additional commands to add to /etc/rc.local
    (SSD and virtual is always 'noop')
* `puppet_host = "puppet.${::trusted['domain']}"` - Puppet Server hostname
* `puppet_cahost = $puppet_host` - Puppet CA hostname
* `puppet_env = $::environment` - Puppet environment
* `puppet_use_dns_srv = false` - enable support DNS SRV records instead of hostnames
* `mcollective = false` - controls if mcollective service is enabled
* `locale = 'en_US.UTF-8'` - default system locale
* `reserve_ram` = 64 - amount of ram to reserve for system in automatic calculations
* `$key_server = 'hkp://pgp.mit.edu:80'` - default PGP key server
* `$random_feed = true` - enable random entropy generating daemon

## `cfsystem::hierapool` class

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


## `cfsystem::email` class

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

## `cfsystem::sysctl` class

Setup sysctl entries.

* `vm_swappiness = 1` - 0-100 (%) minimize swap activity by default

## `cfsystem::debian` class

Debian-specific configuration.

* `apt_url = 'http://httpredir.debian.org/debian'` - APT base URL for Debian repos
* `security_apt_url = 'http://security.debian.org/'` - APT base URL for Debian security repo
* `release` = 'jessie' - Debian release name to configure

## `cfsystem::ubuntu` class

Ubuntu-specific configuration.

* `apt_url = 'mirror://mirrors.ubuntu.com/mirrors.txt'` - APT base URL for Ubuntu repos
* `release = 'wily'` - Ubuntu release name to configure

## `cfsystem::debian::debconf` type

* `package = $title` - package to configure & install
* `ensure = present` - passed to `package ensure`
* `config = []` - config entries for `debconf-set-selections`

## `cfsystem::apt::key` type

Configure APT key & add automatic update of expired keys

* `id` - PGP key ID
* `extra_opts = {}` - any additional options for `apt::key`

## `cfsystem::dotenv` type

A special helper to create entries in user ~/.env files

* `user` - previously defined user{ $user: home => 'path'} ($home must be explicitly set)
* `variable` - variable name
* `value` - value
* `env_file = '.env'` - name of .env file relative to $home

## `cfsystem::puppetpki` type
Make actual Puppet PKI (CA, CRL, client cert and private key) data available to specific user.
By default the data is copied under ~/pki/puppet/.

* `user = $title` - local user to use
* `copy_key = true` - if true then private keys of local machine are copied as well
* `pki_dir = undef` - override the default destination folder

## `cfsystem::haproxy` class

Setup haproxy package. No configuration. Used by other modules

* `$disable_standard = true` - controls if default HAProxy service must be disabled

## `cfsystem::randomfeed` class

Setup random entropy generating tools

* `$type = 'haveged'` - tools type
* `$threshold = 2048` - minimal random entropy level

## `cfsystem::hwm` class

Generic class for HardWare Management

* `Enum['none', 'auto', 'generic', 'dell', 'smc'] $type = 'auto'` - 
    select type of HW vendor, if auto-detection fails.

## `cfsystem::hwm::generic` class

Just a placeholder for generic IPMI system.

## `cfsystem::hwm::dell` class

Support for Dell PowerEdge family.

* `$community_repo = 'http://linux.dell.com/repo/community'`

## `cfsystem::hwm::smc` class

Placeholder for SuperMicro support. Not implemented yet.

[cfnetwork]: https://github.com/codingfuture/puppet-cfnetwork
[cfauth]: https://github.com/codingfuture/puppet-cfauth
[cffirehol]: https://github.com/codingfuture/puppet-cffirehol