class raspi::epim {

    package { ['python3-requests']:
        ensure => installed
    }

    file { '/etc/epim.ini':
        ensure  => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        content => epp(
            'raspi/epim.ini.epp',
            {
                'cg_einkdisp_username' => $secure::cg_einkdisp_username,
                'cg_einkdisp_password' => $secure::cg_einkdisp_password
            }
        )
    }

    file { "/etc/systemd/system/epim.service":
        source => 'puppet:///modules/raspi/epaperdisplay/epim.service',
        owner => 'root',
        group => 'root',
        mode => '0644',
        notify => Exec['daemon-reload']
    } ->
    file { "/etc/systemd/system/epim.timer":
        source => 'puppet:///modules/raspi/epaperdisplay/epim.timer',
        owner => 'root',
        group => 'root',
        mode => '0644',
        notify => Exec['daemon-reload']
    } ->
    service { 'epim.timer':
        ensure  => 'running',
        enable => true
    }
}
