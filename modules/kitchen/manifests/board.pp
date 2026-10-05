class kitchen::board {

    group { 'kitchen':
        ensure => 'present',
        gid    => 21005
    }

    # A real home and shell, because GDM autologin needs both.
    user { 'kitchen':
        ensure     => 'present',
        comment    => 'Kitchen wall panel kiosk user',
        uid        => 19005,
        gid        => 'kitchen',
        home       => '/home/kitchen',
        managehome => true,
        shell      => '/bin/bash',
        require    => Group['kitchen']
    }

    base::addusertogroup { 'Allow kitchen panel backlight and touch access':
        ensure    => 'exists',
        username  => 'kitchen',
        groupname => 'paneltouch',
        require   => [User['kitchen'], Group['paneltouch']]
    }
    base::addusertogroup { 'Allow woolie panel backlight and touch access':
        ensure    => 'exists',
        username  => 'woolie',
        groupname => 'paneltouch',
        require   => Group['paneltouch']
    }

    # raspi::pmsensor also needs this on ktcdh1
    stdlib::ensure_packages(['python3-venv'])

    exec { 'Create kitchen venv':
        command => '/usr/bin/python3 -m venv /opt/kitchen-venv',
        creates => '/opt/kitchen-venv/bin/python3',
        require => Package['python3-venv']
    } ->
    exec { 'Install python dependencies into kitchen venv':
        command  => '/opt/kitchen-venv/bin/pip install requests google-api-python-client google-auth',
        unless   => "/opt/kitchen-venv/bin/python3 -c 'import requests, googleapiclient, google.oauth2'",
        provider => 'shell'
    }

    file { '/opt/kitchen':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => true,
        # A file deleted from the repo must disappear from the Pi, or a stale
        # module keeps getting imported.
        purge   => true,
        force   => true,
        # A stale .pyc built by a different Python version is a confusing enough
        # failure to be worth excluding explicitly.
        ignore  => ['__pycache__', '*.pyc'],
        source  => 'puppet:///modules/kitchen/kitchen',
        notify  => Service['kitchen-board']
    }

    file { '/etc/kitchen':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'kitchen',
        mode    => '0750',
        require => Group['kitchen']
    }

    file { '/etc/kitchen/config.toml':
        ensure    => 'present',
        owner     => 'root',
        group     => 'kitchen',
        mode      => '0640',
        show_diff => false,
        content   => epp('kitchen/config.toml.epp', {
            'calendar_ids'      => $secure::kitchen_calendar_ids,
            'weather_latitude'  => $secure::kitchen_weather_latitude,
            'weather_longitude' => $secure::kitchen_weather_longitude,
            'lock_pin'          => $secure::kitchen_lock_pin,
        }),
        require   => File['/etc/kitchen'],
        notify    => Service['kitchen-board']
    }

    # Read-only Google Calendar credentials
    file { '/etc/kitchen/service-account.json':
        ensure    => 'present',
        owner     => 'root',
        group     => 'kitchen',
        mode      => '0640',
        show_diff => false,
        content   => $secure::kitchen_service_account_json,
        require   => File['/etc/kitchen'],
        notify    => Service['kitchen-board']
    }

    file { '/var/lib/kitchen':
        ensure  => 'directory',
        owner   => 'kitchen',
        group   => 'kitchen',
        mode    => '0750',
        require => User['kitchen']
    }

    file { '/etc/systemd/system/kitchen-board.service':
        source => 'puppet:///modules/kitchen/board/kitchen-board.service',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify => [
            Exec['daemon-reload'],
            Service['kitchen-board']
        ]
    }

    service { 'kitchen-board':
        ensure  => running,
        enable  => true,
        require => [
            Exec['Install python dependencies into kitchen venv'],
            File['/opt/kitchen'],
            File['/etc/kitchen/config.toml'],
            File['/etc/kitchen/service-account.json'],
            File['/var/lib/kitchen'],
            File['/etc/systemd/system/kitchen-board.service'],
            Exec['daemon-reload'],
            Base::Addusertogroup['Allow kitchen panel backlight and touch access']
        ]
    }
}
