#
# Copyright 2017 (c) Andrey Galkin
#

define cfsystem::clusterssh(
    String[1]
        $namespace,
    String[1]
        $cluster,
    Boolean
        $is_primary,
    String[1]
        $user,
    String[1]
        $group = $user,
    Enum['rsa', 'ed25519']
        $key_type = 'ed25519',
    Integer[2048]
        $key_bits = 2048, # for rsa
    Array[String[1]]
        $peers = [],
) {
    if $title != "${namespace}:${cluster}" {
        file("Invalid clusterssh title = ${title}")
    }

    $home = getparam(User[$user], 'home')
    $ssh_dir = "${home}/.ssh"
    $ssh_idkey = "${ssh_dir}/id_${cluster}"
    $persist_title = "keys:${title}"

    if !$home or $home == '' {
        fail("User ${user} must be defined with explicit 'home' parameter")
    }

    if getparam(User[$user], 'purge_ssh_keys') != true {
        fail("User ${user} must be defined with purge_ssh_keys=true")
    }

    $key_gen_opts = {
        type => $key_type,
        bits => $key_bits
    }

    if $is_primary {
        $key_info = cf_genkey($title, $key_gen_opts)
    } else {
        $cluster_q = "cfsystem::clusterssh[${title}]{ is_primary = true }"
        $resource_q = "cfsystem_persist[${persist_title}]"
        $cluster_info = cf_query_resources($cluster_q, $resource_q, false)

        if size($cluster_info) != 1 {
            fail("Failed to fetch primary node info for clusterssh[${title}]")
        }

        $key_info = $cluster_info[0]['parameters']['value']
    }

    # TODO: see security notes below
    cfsystem_persist { "keys:${title}":
        section => 'keys',
        key     => $title,
        value   => $key_info,
    }

    User[$user] ->
    file { $ssh_dir:
        ensure => directory,
        owner  => $user,
        group  => $group,
        mode   => '0700',
    } ->
    file { "${ssh_dir}/config":
        owner   => $user,
        group   => $group,
        mode    => '0600',
        content => [
            'StrictHostKeyChecking no',
            "IdentityFile ${ssh_idkey}",
        ].join("\n")
    }

    # TODO: YES, it's insecure as the private key gets stored in catalog
    # in clear text. Need some sort of host-specific encryption.
    file { $ssh_idkey:
        owner   => $user,
        group   => $group,
        mode    => '0600',
        content => $key_info['private'],
    }

    # TODO: options from=
    # It required hostname to be resolved to IPs due to UseDNS=no
    ssh_authorized_key { $ssh_idkey:
        ensure  => present,
        user    => $user,
        type    => $key_info['type'],
        key     => $key_info['public'],
        require => File[$ssh_dir],
    }

    if size($peers) > 0 {
        cfnetwork::client_port { "any:cfssh:${namespace}_${cluster}":
            dst  => $peers,
            user => $user,
        }
        cfnetwork::service_port { "any:cfssh:${namespace}_${cluster}":
            src => $peers,
        }
    }
}
