class base::pki {

    group { 'wooldrigepkicertaccess':
        ensure  => present,
        gid     => 19004
    } ->
    file { "/etc/wooldrigepki":
        ensure => 'directory',
        owner => 'root',
        group => 'wooldrigepkicertaccess'
    } ->
    file { "/etc/wooldrigepki/certificates":
        ensure => 'directory',
        owner => 'root',
        group => 'wooldrigepkicertaccess'
    } ->
    file { "/etc/wooldrigepki/privatekeys":
        ensure => 'directory',
        owner => 'root',
        group => 'wooldrigepkicertaccess'
    } ->
    file { "/etc/wooldrigepki/certificates/root.pem":
        source  => 'puppet:///modules/base/WooldrigePKI_root_CA_1.certificate.pem',
        owner => 'root',
        group => 'wooldrigepkicertaccess',
        mode => '0644'
    }


    # Don't manage the contents of these files, just set restrictive permissions
    # Annoyingly this will create non-existing files as blank, but won't modify
    # existing ones.
    #
    # If a something needs access to one of these, add that user to the
    # wooldrigepkicertaccess group using base::addusertogroup
    file { [
            "/etc/wooldrigepki/certificates/client.pem",
            "/etc/wooldrigepki/certificates/server.pem",
            "/etc/wooldrigepki/privatekeys/client.pem",
            "/etc/wooldrigepki/privatekeys/server.pem"
        ]:
        ensure => 'file',
        replace => false,
        owner => 'root',
        group => 'wooldrigepkicertaccess',
        mode  => '0640',
        require => [
            Group['wooldrigepkicertaccess'],
            File["/etc/wooldrigepki/certificates/root.pem"]
        ]
    }
}
