class httpd ($http_port=80, $webmaster='webmaster@example.com') {
    Httpd::Init <| |> -> Httpd::Module <| |>
    Httpd::Init <| |> -> Httpd::Site <| |>
    Httpd::Init <| |> -> Httpd::Status <| |>
    Httpd::Init <| |> -> Httpd::Defaultvhost <| |>

    package { [ 'apache2', 'apache2-mpm-prefork' ]:
        ensure => installed
    }
    package { ['apache2-mpm-event',
               'apache2-mpm-perchild',
               'apache2-mpm-worker' ]:
        ensure => absent,
    }

    file { '/etc/apache2/apache2.conf':
        content => template('httpd/apache2.conf'),
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0400',
        require => Package['apache2'],
        notify  => Service['apache2']
    }
    file { '/etc/apache2/conf.d/sites':
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0750',
        require => Package['apache2']
    }
    file { '/var/log/apache2/vhost':
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0750',
        require => Package['apache2']
    }
    file { '/etc/logrotate.d/apache2-vhosts':
        source  => 'puppet:///modules/httpd/vhost_logrotate',
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0400',
        require => Package['apache2'],
        notify  => Service['apache2']
    }

    service { 'apache2':
        ensure     => running,
        enable     => true,
        hasrestart => true,
        require    => Package['apache2']
    }
}
