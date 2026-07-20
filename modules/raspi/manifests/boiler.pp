class raspi::boiler {

    package { ['python3-gpiozero', 'pigpio', 'python3-pigpio']:
        ensure => installed
    }

    # pytz + InfluxDB client: pip3 on pre-PEP-668 hosts (22.04/Raspbian 11), apt packages on Ubuntu 24.04+
    if $facts['os']['release']['major'] in ['22.04', '11'] {
        package { ['pytz', 'influxdb-client']:
            ensure   => installed,
            provider => 'pip3',
            require  => Package['python3-pip'],
        }
    } else {
        package { ['python3-tz', 'python3-influxdb-client']:
            ensure => installed,
        }
    }

    service { 'pigpiod':
        ensure  => 'running',
        enable  => true,
        require => Package['python3-pigpio'],
    }

    file { '/usr/bin/boilerctl':
        source  => 'puppet:///modules/raspi/boiler/boilerctl',
        owner   => 'root',
        group   => 'root',
        mode    => '755',
        require => [Package['python3-click'], Service['pigpiod']],
    }

    cron { 'Run boilerctl autoset every minute':
        ensure  => 'present',
        command => '/usr/bin/systemd-cat -t "boilerctl" /usr/bin/boilerctl autoset',
        user    => root,
        require => File['/usr/bin/boilerctl'],
    }

}
