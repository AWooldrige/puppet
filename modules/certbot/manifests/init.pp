class certbot {
    package { 'certbot':
        ensure => installed,
    }->
    exec { 'Run certbot to create /etc/letsencrypt/renewal-hooks':
        # Yes this isn't very nice, but running an arbitrary certbot command
        # is the only way to get these directories create now (unless tracking
        # and doing it manually).
        # https://github.com/certbot/certbot/issues/9530#issuecomment-1492186349
        creates => '/etc/letsencrypt/renewal-hooks',
        command => '/usr/bin/certbot certificates --noninteractive'
    } ->
    file { '/etc/letsencrypt/renewal-hooks/post/01-reload-nginx':
        source  => 'puppet:///modules/certbot/01-reload-nginx',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package['certbot']
    }
}
