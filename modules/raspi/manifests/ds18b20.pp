class raspi::ds18b20 {

    file { '/usr/bin/ds18b20_manager':
        source => 'puppet:///modules/raspi/ds18b20/ds18b20_manager',
        owner  => 'root',
        group  => 'root',
        mode   => '755'
    } ->
    cron { 'Run ds18b20_manager every minute':
        ensure => 'present',
        command => '/usr/bin/systemd-cat -t "ds18b20" /usr/bin/ds18b20_manager',
        user    => root
    }
}
