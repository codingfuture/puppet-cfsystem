
define cfsystem::debian::debconf (
    $package = $title,
    $ensure = present,
    $config = [],
) {
    $cfg_file = "/etc/cfsystem/debconf/${package}.debconf"
    
    if $ensure != absent {
        file { $cfg_file:
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            content => join($config, "\n"),
        } ->
        exec { "cfsystem_debconf_${package}":
            command     => "/usr/bin/debconf-set-selections <${cfg_file}",
            refreshonly => true,
        } ->
        package { $package:
            ensure => $ensure,
        }
        
        exec { "cfsystem_dpkgreconf_${package}":
            command     => "/usr/sbin/dpkg-reconfigure ${package}",
            refreshonly => true,
            require     => Package[$package],
            subscribe   => Exec["cfsystem_debconf_${package}"]
        }
    } else {
        file { $cfg_file: ensure => absent }
        package { $package: ensure => $ensure }
    }
}