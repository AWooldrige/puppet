class raspi::autologin {
    # All of this is recreating what /usr/bin/raspi-config does when running
    # do_boot_behaviour.

    file { '/etc/systemd/system/default.target':
        ensure => 'link',
        target => '/lib/systemd/system/graphical.target'
    }

    file { '/etc/systemd/system/getty.target.wants/getty@tty1.service':
        ensure => 'link',
        target => '/etc/systemd/system/autologin@.service'
    }

    file_line { 'Set agetty autologin':
        path => '/etc/systemd/system/autologin@.service',
        line => 'ExecStart=-/sbin/agetty --autologin woolie --noclear %I $TERM',
        match => '^ExecStart=-/sbin/agetty',
        append_on_no_match => false
    }

    file_line { 'Set lightdm autologin':
        path => '/etc/lightdm/lightdm.conf',
        line => 'autologin-user=woolie',
        match => '^#?autologin-user=',
        append_on_no_match => false
    }
}

