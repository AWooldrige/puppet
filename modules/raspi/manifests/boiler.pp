class raspi::boiler {

    package { [
            'python3-gpiozero',
            'python3-tz',
            'python3-influxdb-client'
        ]:
        ensure => installed
    }

    file { '/usr/bin/boilerctl':
        source  => 'puppet:///modules/raspi/boiler/boilerctl',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => [
            Package['python3-click'],
            Package['python3-gpiozero'],
            Package['python3-lgpio']
        ]
    } ->
    cron { 'Run boilerctl autoset every minute':
        ensure  => 'present',
        command => '/usr/bin/systemd-cat -t "boilerctl" /usr/bin/boilerctl autoset',
        user    => root
    }
}
