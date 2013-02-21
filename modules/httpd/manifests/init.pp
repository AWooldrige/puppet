class httpd (
    $http_port=80,
    $https_port=443,
    $status_port=8000) {

    package { [ "apache2", "apache2-mpm-prefork", "ssl-cert" ]:
        ensure => installed
    }
    package { ["apache2-mpm-event", "apache2-mpm-perchild", "apache2-mpm-worker"]:
        ensure => absent,
    }

    file {"/var/log/apache2/vhost":
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '750',
        require => Package['apache2']
    }
    file { "/etc/logrotate.d/apache2-vhosts":
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '400',
        require => Package['apache2'],
        source => 'puppet:///modules/httpd/vhost_logrotate',
        notify  => Service['apache2']
    }
    file { "/etc/apache2/conf.d/fqdn":
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '400',
        require => Package['apache2'],
        content => template("httpd/conf.d/fqdn"),
        notify  => Service['apache2']
    }
    file { "/etc/apache2/conf.d/security":
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '400',
        require => Package['apache2'],
        content => template("httpd/conf.d/security"),
        notify  => Service['apache2']
    }
    file { "/etc/apache2/apache2.conf":
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '400',
        require => Package['apache2'],
        content => template("httpd/apache2.conf"),
        notify  => Service['apache2']
    }
    file { "/etc/apache2/ports.conf":
        ensure => absent
    }
    file { "/etc/apache2/conf.d/ports.conf":
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '400',
        require => Package['apache2'],
        content => template("httpd/conf.d/ports.conf"),
        notify  => Service['apache2']
    }
    file {"/etc/apache2/conf.d/sites":
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '750',
        require => Package['apache2']
    }
    service { "apache2":
        ensure  => running,
        enable  => true,
        hasrestart => true,
        require => Package['apache2'],
        notify => Service['varnish']
    }


    exec { "reload-apache2":
        command => "/etc/init.d/apache2 reload",
        refreshonly => true,
        before => [ Service["apache2"], Exec["force-reload-apache2"] ]
    }
    exec { "force-reload-apache2":
        command => "/etc/init.d/apache2 force-reload",
        refreshonly => true,
        before => Service["apache2"],
    }


    exec { 'regenerate-snakeoil-certs':
        command => "/usr/sbin/make-ssl-cert generate-default-snakeoil --force-overwrite",
        refreshonly => true,
        before => Package["apache2"]
    }


    # Default site
    file { '/var/www/default':
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '700',
        require => Package['apache2']
    }
    file { "/etc/apache2/sites-available/default":
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '600',
        content => template("httpd/vhosts/default"),
        notify  => Service['apache2'],
        require => File['/var/www/default/index.html']
    }
    file { '/var/www/default/index.html':
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '400',
        content => template("httpd/default/index.html"),
        require => File['/var/www/default']
    }
    httpd::site { 'default':
        ensure => enabled
    }


    # Exposing mod_status output locally to diamond
    file { "/etc/apache2/mods-available/status.conf":
        source => 'puppet:///modules/httpd/status.conf',
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '400',
        require => Package['apache2'],
        notify  => Service['apache2']
    }
    httpd::module{ 'status':
       ensure => enabled,
       require => File["/etc/apache2/mods-available/status.conf"]
    }

    file { "/etc/apache2/sites-available/status":
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '600',
        content => template("httpd/vhosts/status"),
        require => Package['apache2'],
        notify  => Service['apache2']
    }
    httpd::site { 'status':
        ensure => enabled
    }
    file { "/etc/diamond/collectors/HttpdCollector.conf":
        owner => 'root',
        group => 'root',
        mode => '400',
        content => template("httpd/diamond/HttpdCollector.conf"),
        notify => Service['diamond']
    }
}
