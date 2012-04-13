class woolie-co-uk () {

    $http_port = extlookup('httpd/http_port')
    $https_port = extlookup('httpd/https_port')

    file { "/etc/apache2/sites-available/woolie-co-uk":
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '400',
        content => template("woolie-co-uk/conf"),
        require => Package['apache2'],
        notify  => Service['apache2'],
    }

    httpd::site { 'woolie-co-uk':
        ensure => enabled
    }


    wordpress::instance {'woolie.co.uk':
        ensure  => "3.3.1",
        path    => "/var/www/woolie-co-uk",
        domain  => "woolie.co.uk",
        backups => false,
        require => Httpd::Site['woolie-co-uk']
    }
}
