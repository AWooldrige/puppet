class woolie-co-uk () {

    $http_port = extlookup('httpd/http_port')
    $https_port = extlookup('httpd/https_port')

    $db = 'woolie_co_uk_wp'
    $user = 'woolie_co_uk_wp'
    $pass = extlookup('woolie-co-uk/password')

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
        require => Package['apache2'],
        notify  => Service['apache2'],
    }

    httpd::site { 'woolie-co-uk':
        ensure => enabled
    }


    mysql::db { $db:
        user     => $user,
        password => $pass,
        host     => 'localhost',
        grant    => ['select', 'insert', 'update', 'delete', 'create', 'index',
                     'alter', 'show_db', 'create_tmp_table', 'lock_tables'],
    }
}
