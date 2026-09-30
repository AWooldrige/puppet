class ubutils::flatpakfuse {
    # Let Flatpak apps (Cryptomator) mount FUSE filesystems on Ubuntu 26.04.
    exec { 'apparmor-reload-fusermount3':
        command     => '/usr/sbin/apparmor_parser --replace --skip-read-cache --write-cache /etc/apparmor.d/fusermount3',
        onlyif      => '/usr/bin/test -e /etc/apparmor.d/fusermount3',
        refreshonly => true,
    }

    file { '/etc/apparmor.d/local/fusermount3':
        source => 'puppet:///modules/ubutils/apparmor-local-fusermount3',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify => Exec['apparmor-reload-fusermount3'],
    }
}
