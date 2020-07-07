class raspi::wifi {

    file { '/etc/cloud/cloud.cfg.d/99-disable-network.cfg':
        ensure => 'present',
        content => 'network: {config: disabled}',
        owner   => 'root',
        group   => 'root',
        mode    => '0644'
    }->
    file { '/etc/netplan/49-netplan-woolie.yaml':
        ensure  => 'present',
        content => epp(
            'raspi/49-netplan-woolie.yaml.epp',
            {
                'wifi_ssid' => $secure::wifi_ssid,
                'wifi_password' => $secure::wifi_password
            }
        ),
        notify => Exec['netplan-apply']
    }

    exec { 'netplan-apply':
        refreshonly => true,
        command => '/usr/sbin/netplan apply',
    }
}
