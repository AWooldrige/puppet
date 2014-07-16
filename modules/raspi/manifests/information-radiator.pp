class raspi::information-radiator {
    file { '/usr/bin/launch-information-radiator':
        source => 'puppet:///modules/raspi/launch-information-radiator.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '755'
    }
    cron { 'launch-afternoon-pages':
        ensure  => present,
        command => "/usr/bin/launch-information-radiator",
        user    => pi,
        minute  => 0,
        require => User['pi']
    }
}
