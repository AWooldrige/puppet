class raspi::information-radiator {
    file { '/usr/bin/launch-information-radiator':
        source => 'puppet:///modules/raspi/launch-information-radiator.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }
    cron { ['launch-afternoon-pages', 'relaunch-information-radiator-at-boot']:
        ensure  => absent
    }
    cron { 'relaunch-information-radiator-every-so-often':
        ensure  => present,
        command => "/usr/bin/launch-information-radiator",
        user    => pi,
        hour    => [6, 17],
        require => User['pi']
    }
    file { '/home/pi/.config/autostart':
        source => 'puppet:///modules/raspi/lxde-autostart',
        owner  => 'pi',
        group  => 'pi',
        mode   => '0644',
        require => User['pi']
    }
}
