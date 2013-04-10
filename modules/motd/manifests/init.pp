class motd {
    file { '/etc/issue':
        source => 'puppet:///modules/motd/issue',
        owner  => 'root',
        group  => 'root',
        mode   => '0644'
    }
    file { '/etc/issue.net':
        source => 'puppet:///modules/motd/issue',
        owner  => 'root',
        group  => 'root',
        mode   => '0644'
    }

    # Disable the current MOTD scripts
    file { [
        '/etc/update-motd.d/00-header',
        '/etc/update-motd.d/10-help-text',
        '/usr/share/landscape/landscape-sysinfo.wrapper',
        '/etc/update-motd.d/90-updates-available',
        '/etc/update-motd.d/91-release-upgrade',
        '/etc/update-motd.d/98-fsck-at-reboot',
        '/etc/update-motd.d/98-reboot-required',
        '/etc/update-motd.d/99-footer'
        ]:
        owner => 'root',
        group => 'root',
        mode  => '0644'
    }

    file { '/etc/update-motd.d/00-custom-motd':
        content => template('motd/motd'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755'
    }
}
