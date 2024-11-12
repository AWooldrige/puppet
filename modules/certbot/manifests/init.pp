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
    file { '/etc/woolie_user_certbot_env_vars.conf':
        source  => 'puppet:///modules/certbot/woolie_user_certbot_env_vars.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0755'
    } ->
    file_line { 'Add Route53 AWS credentials in to certbot renewal timer/oneshot service':
        # Adding this in to the certbot provided systemd timer isn't very nice,
        # but it's the only way to get auto renewals to use the correct
        # credentials. See: https://github.com/certbot/certbot/issues/7873
        ensure  => present,
        path    => '/usr/lib/systemd/system/certbot.service',
        line    => 'EnvironmentFile=/etc/woolie_user_certbot_env_vars.conf',
        after   => '^\[Service\]$'
    }
}

