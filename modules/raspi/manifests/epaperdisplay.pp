class raspi::epaperdisplay {

    exec { 'daemon-reload':
        command => '/usr/bin/systemctl daemon-reload',
        refreshonly => true
    }

    exec { 'Clone waveshare ePaper repo':
       command => '/usr/bin/git clone https://github.com/waveshare/e-Paper /opt/epaperlibs',
       creates => '/opt/epaperlibs/README.md',
       require => Package['git']
    } ->
    file { '/usr/local/bin/displaytestcard':
        source => 'puppet:///modules/raspi/epaperdisplay/displaytestcard',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    } ->
    file { '/etc/systemd/system/displaytestcard.service':
        source => 'puppet:///modules/raspi/epaperdisplay/displaytestcard.service',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify => Exec['daemon-reload']
    } ->
    service { 'displaytestcard':
        ensure => running,
        enable => true
    }
}
