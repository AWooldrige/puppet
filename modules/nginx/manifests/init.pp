class nginx ($http_port=80) {
    package { 'nginx':
        ensure => installed
    }
    file { "/etc/nginx/nginx.conf":
        content => template('nginx/nginx.conf'),
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify  => Service['nginx'],
        require  => Package['nginx']
    }
    service { 'nginx':
        ensure     => running,
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        require    => Package['nginx']
    }
}
