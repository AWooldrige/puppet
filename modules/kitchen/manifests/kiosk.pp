class kitchen::kiosk {

    include kitchen::board
    include dconf

    $profile_dir = '/home/kitchen/snap/firefox/common/kiosk-profile'

    # Declared so the file_line resources have something to edit
    package { 'gdm3':
        ensure => installed
    }

    # file_line, never a whole-file replacement: custom.conf is login-critical
    file_line { 'Enable GDM autologin':
        path               => '/etc/gdm3/custom.conf',
        line               => 'AutomaticLoginEnable=true',
        # Ubuntu ships the key commented out; match either form.
        match              => '^#?\s*AutomaticLoginEnable\s*=',
        append_on_no_match => true,
        after              => '^\[daemon\]',
        require            => Package['gdm3']
    }
    file_line { 'Set GDM autologin user':
        path               => '/etc/gdm3/custom.conf',
        line               => 'AutomaticLogin=kitchen',
        match              => '^#?\s*AutomaticLogin\s*=',
        append_on_no_match => true,
        after              => '^\[daemon\]',
        require            => File_line['Enable GDM autologin']
    }

    file { '/etc/dconf/db/local.d/30-kitchen-kiosk':
        source  => 'puppet:///modules/kitchen/kiosk/30-kitchen-kiosk',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => File['/etc/dconf/db/local.d'],
        notify  => Exec['dconf-update']
    }

    file { '/etc/dconf/db/local.d/locks':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => File['/etc/dconf/db/local.d']
    } ->
    file { '/etc/dconf/db/local.d/locks/30-kitchen-kiosk':
        source => 'puppet:///modules/kitchen/kiosk/30-kitchen-kiosk.locks',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify => Exec['dconf-update']
    }

    file { '/home/kitchen/.config':
        ensure  => 'directory',
        owner   => 'kitchen',
        group   => 'kitchen',
        mode    => '0755',
        require => User['kitchen']
    } ->
    file { '/home/kitchen/.config/monitors.xml':
        source => 'puppet:///modules/kitchen/kiosk/monitors.xml',
        owner  => 'kitchen',
        group  => 'kitchen',
        mode   => '0644'
    }

    snap::package { 'firefox':
        ensure => 'installed'
    }

    # Snap creates these on first run, but the profile has to exist before the
    # kiosk unit starts, and on a fresh box that is the same boot.
    file { [
            '/home/kitchen/snap',
            '/home/kitchen/snap/firefox',
            '/home/kitchen/snap/firefox/common',
            $profile_dir
        ]:
        ensure  => 'directory',
        owner   => 'kitchen',
        group   => 'kitchen',
        mode    => '0700',
        require => User['kitchen']
    }

    # user.js is re-read on every start
    file { "${profile_dir}/user.js":
        source  => 'puppet:///modules/kitchen/kiosk/firefox-user.js',
        owner   => 'kitchen',
        group   => 'kitchen',
        mode    => '0600',
        require => File[$profile_dir]
    }

    # Snap refreshes cannot be prevented, only scheduled.
    exec { 'Pin snap refreshes to the small hours':
        command  => "/usr/bin/snap set system refresh.timer='03:30-04:30'",
        unless   => "/usr/bin/snap get system refresh.timer | /usr/bin/grep -qxF '03:30-04:30'",
        provider => 'shell',
        require  => Package['snapd']
    }

    cron { 'Reboot the kitchen panel overnight':
        command => '/usr/bin/systemd-cat -t "kitchen-reboot" /usr/sbin/reboot',
        user    => root,
        hour    => 2,
        minute  => 0
    }

    # Two launchers, so the panel is recoverable and usable by hand
    file { '/usr/local/bin/kitchen-browse':
        source => 'puppet:///modules/kitchen/kiosk/kitchen-browse',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }

    file { [
            '/home/kitchen/.local',
            '/home/kitchen/.local/share',
            '/home/kitchen/.local/share/applications',
            '/home/kitchen/Desktop'
        ]:
        ensure  => 'directory',
        owner   => 'kitchen',
        group   => 'kitchen',
        mode    => '0755',
        require => User['kitchen']
    }

    ['kitchen-board', 'kitchen-browse'].each |$launcher| {
        file { "/home/kitchen/.local/share/applications/${launcher}.desktop":
            source  => "puppet:///modules/kitchen/kiosk/${launcher}.desktop",
            owner   => 'kitchen',
            group   => 'kitchen',
            mode    => '0755',
            require => File['/home/kitchen/.local/share/applications']
        }

        file { "/home/kitchen/Desktop/${launcher}.desktop":
            source  => "puppet:///modules/kitchen/kiosk/${launcher}.desktop",
            owner   => 'kitchen',
            group   => 'kitchen',
            mode    => '0755',
            require => File['/home/kitchen/Desktop']
        }
    }

    file { '/etc/systemd/user/kitchen-kiosk.service':
        source => 'puppet:///modules/kitchen/kiosk/kitchen-kiosk.service',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify => Exec['daemon-reload']
    } ->
    # --global rather than --user: enables the unit for every user session that
    # starts, so there is no per-user state to lose when the home directory is
    # rebuilt.
    exec { 'Enable the kitchen kiosk user unit':
        command => '/usr/bin/systemctl --global enable kitchen-kiosk.service',
        creates => '/etc/systemd/user/graphical-session.target.wants/kitchen-kiosk.service',
        require => File['/etc/systemd/user/kitchen-kiosk.service']
    }
}
