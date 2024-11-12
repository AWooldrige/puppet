class backuptool {

    file { '/etc/backuptool_passphrase':
        owner  => 'root',
        group  => 'root',
        mode   => '0600',
        content => $secure::backuptool_passphrase
    } ->
    file { '/usr/local/sbin/backuptool':
        source => 'puppet:///modules/backuptool/backuptool',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }
}
