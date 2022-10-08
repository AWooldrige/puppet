class raspi::boiler {

    package { ['python3-gpiozero', 'python3-click', 'pigpio', 'python3-pigpio']:
        ensure => installed
    } ->
    package { 'pytz':
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
        mode   => '755'
    } ->
    cron { 'Run boilerctl autoset every minute':
        ensure => 'present',
        command => '/usr/bin/systemd-cat -t "boilerctl" /usr/bin/boilerctl',
        user    => root
    }

}
