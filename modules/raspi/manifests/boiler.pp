class raspi::boiler {

    package { ['python3-gpiozero', 'pigpio', 'python3-pigpio']:
        ensure => installed
    } ->
    package { ['pytz', 'influxdb-client']:
        ensure => installed,
        provider => 'pip3',
        require => Package['python3-pip']
    } ->
    service { 'pigpiod':
        ensure  => 'running',
        enable => true
    } ->
    file { '/usr/bin/boilerctl':
        source => 'puppet:///modules/raspi/boiler/boilerctl',
        owner  => 'root',
        group  => 'root',
        mode   => '755',
        require => Package['python3-click']
    } ->
    cron { 'Run boilerctl autoset every minute':
        ensure => 'present',
        command => '/usr/bin/systemd-cat -t "boilerctl" /usr/bin/boilerctl autoset',
        user    => root
    }

}
