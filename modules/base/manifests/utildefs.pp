class base::utildefs {

    exec { 'daemon-reload':
        command => '/usr/bin/systemctl daemon-reload',
        refreshonly => true
    }

    exec { 'udev-reload':
        command => '/usr/bin/udevadm control --reload-rules && /usr/bin/udevadm trigger',
        provider => "shell",
        refreshonly => true
    }
}
