class woolie-co-uk () {
    wordpress::instance {'woolie.co.uk':
        ensure  => "3.3.1",
        path    => "/var/www/woolie-co-uk",
        domain  => "woolie.co.uk",
        backups => true,
    }
}
