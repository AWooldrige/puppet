class podman {
    package { 'podman':
        ensure => installed,
        require => [
            Class['apt::update']
        ]
    }
}
