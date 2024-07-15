class docker::docker {
    include docker::repos

    package { 'docker-ce':
        ensure => installed,
        require => [
            Apt::Source['docker'],
            Class['apt::update']
        ]
    }
    service { 'docker':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        enable     => true
    }
}
