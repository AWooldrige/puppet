class raspi::information-radiator {
    file { '/usr/bin/launch-information-radiator':
        source => 'puppet:///modules/raspi/launch-information-radiator.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '755'
    }
    cron { 'launch-afternoon-pages':
        ensure  => absent
    }
    cron { 'relaunch-information-radiator-every-so-often':
        ensure  => present,
        command => "/usr/bin/launch-information-radiator",
        user    => pi,
        hour    => [6, 17],
        require => User['pi']
    }
    cron { 'relaunch-information-radiator-at-boot':
        ensure  => present,
        command => "/usr/bin/launch-information-radiator",
        user    => pi,
        special => 'reboot',
        require => User['pi']
    }
}
