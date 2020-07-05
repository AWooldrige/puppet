class certbot {
    package { 'certbot':
        ensure => installed,
    }->
    file { "/etc/letsencrypt/renewal-hooks/post":
        ensure => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0750'
    }->
    file { '/etc/letsencrypt/renewal-hooks/post/01-reload-nginx':
        source  => 'puppet:///modules/certbot/01-reload-nginx',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package['certbot']
    }
}
