class raspi::ds18b20 {

    file { '/etc/ds18b20_manager.conf' :
        ensure => present,
        mode   => '0644',
        source => "puppet:///modules/raspi/ds18b20/ds18b20_manager.conf.${facts['networking']['hostname']}"
    } ->
    file { '/usr/bin/ds18b20_manager':
        source  => 'puppet:///modules/raspi/ds18b20/ds18b20_manager',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => [
            Package['python3-tenacity'],
            Package['python3-lgpio']
        ]
    } ->
    cron { 'Run ds18b20_manager every minute':
        ensure => 'present',
        command => '/usr/bin/systemd-cat -t "ds18b20" /usr/bin/ds18b20_manager',
        user    => root
    }
}
