class raspi::pmsensor {

    exec {"telegraf dialout":
        provider => 'shell',
        unless => '/usr/bin/groups telegraf | /usr/bin/grep dialout',
        command => '/usr/sbin/usermod -a -G dialout telegraf',
        require => Package['telegraf']
    } ->
    package { 'sds011':
        ensure => installed,
        provider => 'pip3',
        require => Package['python3-pip']
    } ->
    file { '/usr/bin/pmsensor':
        source => 'puppet:///modules/raspi/pmsensor/pmsensor',
        owner  => 'root',
        group  => 'root',
        mode   => '755'
    } ->
    file { '/etc/telegraf/telegraf.d/pmsensor.conf':
        source => 'puppet:///modules/raspi/pmsensor/pmsensor.telegraf.conf',
        owner => 'root',
        group => 'root',
        mode  => '0644',
        require => Package['telegraf'],
        notify => Service['telegraf']
    }
}
