class nginx {
    include certbot
    include stdlib

    package { 'nginx':
        ensure => installed
    }

    file_line { 'Store nginx logs for 10 years instead of 14 days':
        path => '/etc/logrotate.d/nginx',
        line => 'rotate 3650',
        match   => "^.*rotate 14.*$",
        require => Package['nginx']
    }

    file { [
        '/etc/nginx/sites-available/default',
        '/etc/nginx/sites-enabled/default'
        ]:
        ensure => 'absent',
    }

    # Mainly for storing htpasswd files
    file { '/etc/nginx/secrets':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        require => Package['nginx']
    }

    # From: https://ssl-config.mozilla.org/ffdhe4096.txt
    # See: https://news.ycombinator.com/item?id=10398309
    file { '/etc/nginx/ffdhe4096.pem':
        source  => 'puppet:///modules/nginx/ffdhe4096.pem',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['nginx'],
        notify  => Service['nginx']
    }->
    file { '/etc/nginx/snippets/tlsparams.conf':
        source  => 'puppet:///modules/nginx/snippets/tlsparams.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['nginx'],
        notify  => Service['nginx']
    }

    file { '/etc/nginx/conf.d/log-formats.conf':
        source  => 'puppet:///modules/nginx/conf.d/log-formats.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['nginx'],
        notify  => Service['nginx']
    }

    # A handy port that responds in a ping style
    file { "/etc/nginx/sites-available/ping":
        source  => 'puppet:///modules/nginx/sites-available/ping',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify  => Service['nginx']
    } ->
    file { "/etc/nginx/sites-enabled/ping":
        ensure => 'link',
        target => '/etc/nginx/sites-available/ping',
        notify  => Service['nginx']
    }


    file { "/etc/nginx/sites-available/status":
        source  => 'puppet:///modules/nginx/sites-available/status',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify  => Service['nginx']
    } ->
    file { "/etc/nginx/sites-enabled/status":
        ensure => 'link',
        target => '/etc/nginx/sites-available/status',
        notify  => Service['nginx']
    } ->
    file { '/etc/telegraf/telegraf.d/nginx.conf':
        source  => 'puppet:///modules/nginx/telegraf/nginx.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['telegraf'],
        notify  => Service['telegraf']
    }


    # Default virtual host for port 80 + serving of .well-known dir
    file { "/var/www/letsencrypt":
        ensure => 'directory',
        owner   => 'root',
        group   => 'www-data',
        mode    => '0750'
    }->
    file { "/var/www/letsencrypt/.well-known/acme-challenge":
        ensure => 'directory',
        owner   => 'root',
        group   => 'www-data',
        mode    => '0750'
    }->
    file { "/var/www/letsencrypt/.well-known/test.txt":
        ensure => 'present',
        content => 'Permanent fixture test file.',
        owner   => 'root',
        group   => 'www-data',
        mode    => '0640'
    }->
    file { "/etc/nginx/sites-available/default_80":
        source  => 'puppet:///modules/nginx/sites-available/default_80',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify  => Service['nginx']
    } ->
    file { "/etc/nginx/sites-enabled/default_80":
        ensure => 'link',
        target => '/etc/nginx/sites-available/default_80',
        notify  => Service['nginx']
    }


    # Provides snakeoil certs
    package { 'ssl-cert':
        ensure => installed
    } ->
    file { "/etc/nginx/sites-available/default_443":
        source  => 'puppet:///modules/nginx/sites-available/default_443',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify  => Service['nginx']
    } ->
    file { "/etc/nginx/sites-enabled/default_443":
        ensure => 'link',
        target => '/etc/nginx/sites-available/default_443',
        notify  => Service['nginx']
    }

    file { "/etc/nginx/nginx.conf":
        source  => 'puppet:///modules/nginx/nginx.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify  => Service['nginx'],
        require => [
            File["/etc/nginx/sites-enabled/default_80"],
            File["/etc/nginx/sites-enabled/default_443"],
            File["/etc/nginx/sites-enabled/ping"],
            File["/etc/nginx/sites-enabled/status"]
        ]
    }

    service { 'nginx':
        ensure     => running,
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        require   => File['/etc/nginx/nginx.conf']
    }

    # Utility reload exec for other modules
    exec { 'reload-nginx':
        refreshonly => true,
        command => '/usr/bin/systemctl reload nginx',
        require => [
            Service['nginx']
        ]
    }
}
