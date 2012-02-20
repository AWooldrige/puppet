class httpd {
    package { "apache2":
        ensure => latest
    }

    file { "/etc/apache2/conf.d/fqdn":
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '644',
        require => Package['apache2'],
        content => template("httpd/conf.d/fqdn"),
    }
    service { "apache2":
        ensure  => running,
        enable  => true,
        require => Package['apache2'],
    }
}
