class raspi::autowifirestart {

    package { ['watchdog']:
        ensure => installed
    } ->
    file { '/etc/watchdog.conf':
        source => 'puppet:///modules/raspi/autowifirestart/watchdog.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '644',
        notify => Service['watchdog']
    } ->
    service { 'watchdog':
        ensure     => running,
        enable     => true
    }
}
