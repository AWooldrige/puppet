class certbot {
    package {[
        'python3-certbot',
        'python3-certbot-dns-route53'
        ]:
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
        mode    => '0755'
    } ->
    file { '/etc/systemd/system/certbot.service.d':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0755'
    } ->
    file { '/etc/systemd/system/certbot.service.d/aws.conf':
        source  => 'puppet:///modules/certbot/certbot.service.aws.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Exec['daemon-reload']
    }

    file_line { 'Remove the EnvironmentFile from the vendor certbot.service':
        ensure  => absent,
        path    => '/usr/lib/systemd/system/certbot.service',
        line    => 'EnvironmentFile=/etc/woolie_user_certbot_env_vars.conf',
        require => Package['python3-certbot'],
        notify  => Exec['daemon-reload']
    } ->
    file { '/etc/woolie_user_certbot_env_vars.conf':
        ensure  => absent
    }
}

