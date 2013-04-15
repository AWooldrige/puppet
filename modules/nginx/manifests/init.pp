class nginx ($http_port=80) {
    package { 'nginx':
        ensure => installed
    }

    service { 'nginx':
        ensure  => running,
        require => Package['nginx']
    }
}
