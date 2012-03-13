class woolie-co-uk () {

    $http_port = extlookup('httpd/http_port')
    $https_port = extlookup('httpd/https_port')

    file { '/var/www/woolie-co-uk':
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '700',
    }
    file { "/etc/apache2/sites-available/woolie-co-uk":
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '400',
        content => template("woolie-co-uk/conf"),
        notify  => Service['apache2'],
    }

    httpd::site { 'woolie-co-uk':
        ensure => enabled
    }
}
