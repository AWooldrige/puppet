class raspi::information-radiator {
    file { '/usr/bin/launch-information-radiator':
        source => 'puppet:///modules/raspi/launch-information-radiator.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }
    file { '/usr/share/applications/information-radiator.desktop':
        source  => 'puppet:///modules/raspi/information-radiator.desktop',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => File['/usr/bin/launch-information-radiator']
    }

    cron { 'relaunch-information-radiator-every-so-often':
        ensure  => present,
        command => "/usr/bin/launch-information-radiator",
        user    => pi,
        hour    => [6, 17],
        minute  => 0,
        require => User['pi']
    }
    file { '/home/pi/.config/autostart':
        ensure => 'directory,
        owner  => 'pi',
        group  => 'pi',
        mode   => '0755',
        require => User['pi']
    }
    file { '/home/pi/.config/autostart/information-radiator.desktop':
        ensure  => link,
        target  => '/usr/share/applications/information-radiator.desktop',
        require => [
            File['/home/pi/.config/autostart'],
            File['/usr/share/applications/information-radiator.desktop']
        ]
    }
}
