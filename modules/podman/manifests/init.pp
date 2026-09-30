class podman {
    package { 'podman':
        ensure => installed,
        require => [
            Class['apt::update']
        ]
    }

    cron { 'Prune unused podman images weekly':
        ensure  => present,
        command => '/usr/bin/systemd-cat -t "podman-prune" /usr/bin/podman image prune -af',
        weekday => 1,
        hour    => 4,
        minute  => 40,
        require => Package['podman']
    }
}
