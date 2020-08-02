class raspi::epaperdisplay {

    exec { 'daemon-reload':
        command => '/usr/bin/systemctl daemon-reload',
        refreshonly => true
    }

    package { ['python3-pil', 'python3-numpy', 'python3-watchdog']:
        ensure => installed
    } ->
    exec { 'Clone waveshare ePaper repo':
       command => '/usr/bin/git clone https://github.com/waveshare/e-Paper /opt/epaperlibs',
       creates => '/opt/epaperlibs/README.md',
       require => Package['git']
    } ->
    file { '/usr/local/bin/watchanddisplay':
        source => 'puppet:///modules/raspi/epaperdisplay/watchanddisplay',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    } ->
    file { "/etc/systemd/system/watchanddisplay.service":
        source => 'puppet:///modules/raspi/epaperdisplay/watchanddisplay.service',
        owner => 'root',
        group => 'root',
        mode => '0644',
        notify => Exec['daemon-reload']
    } ->
    service { 'watchanddisplay':
        ensure => running,
        enable => true
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
    }
}
