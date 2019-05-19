class raspi::inforad {
    package { ['cec-utils', 'chromium-browser']:
        ensure => installed
    }
    file { '/usr/local/bin/hdmi-screen':
        source => 'puppet:///modules/raspi/hdmi-screen',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        require => Package['cec-utils']
    }
    file { '/usr/local/bin/weekday-morning-browser-start':
        source => 'puppet:///modules/raspi/weekday-morning-browser-start',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        require => Package['chromium-browser']
    }
    file { '/usr/local/bin/weekday-evening-browser-start':
        source => 'puppet:///modules/raspi/weekday-evening-browser-start',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        require => Package['chromium-browser']
    }
    file { '/usr/local/bin/kill-browser':
        source => 'puppet:///modules/raspi/kill-browser',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }

    ###########################################################################
    # Weekday morning crons
    ###########################################################################
    cron { 'Screen on: Weekday mornings':
        command => '/usr/bin/systemd-cat -t "inforad" /usr/local/bin/hdmi-screen on',
        user    => root,
        hour     => 6,
        minute   => 30,
        weekday  => ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
    }
    cron { 'Browser start: Weekday mornings':
        command => '/usr/bin/systemd-cat -t "inforad" /usr/local/bin/weekday-morning-browser-start',
        user    => 'woolie',
        hour     => 6,
        minute   => 32,
        weekday  => ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
    }
    cron { 'Browser stop: Weekday mornings':
        command => '/usr/bin/systemd-cat -t "inforad" /usr/local/bin/kill-browser',
        user    => 'woolie',
        hour     => 7,
        minute   => 40,
        weekday  => ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
    }
    cron { 'Screen off: Weekday mornings':
        command => '/usr/bin/systemd-cat -t "inforad" /usr/local/bin/hdmi-screen on',
        user    => root,
        hour     => 7,
        minute   => 42,
        weekday  => ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
    }

    ###########################################################################
    # Weekday evening crons
    ###########################################################################
    cron { 'Screen on: Weekday evenings':
        command => '/usr/bin/systemd-cat -t "inforad" /usr/local/bin/hdmi-screen on',
        user    => 'root',
        hour     => 17,
        minute   => 30,
        weekday  => ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
    }
    cron { 'Browser start: Weekday evenings':
        command => '/usr/bin/systemd-cat -t "inforad" /usr/local/bin/weekday-evening-browser-start',
        user    => 'woolie',
        hour     => 17,
        minute   => 32,
        weekday  => ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
    }
    cron { 'Browser stop: Weekday evenings':
        command => '/usr/bin/systemd-cat -t "inforad" /usr/local/bin/kill-browser',
        user    => 'woolie',
        hour     => 22,
        minute   => 15,
        weekday  => ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
    }
    cron { 'Screen off: Weekday evenings':
        command => '/usr/bin/systemd-cat -t "inforad" /usr/local/bin/hdmi-screen on',
        user    => 'root',
        hour     => 22,
        minute   => 17,
        weekday  => ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
    }
}
