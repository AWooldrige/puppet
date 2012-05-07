class woolie-co-uk () {
    wordpress::instance {'wooliecouk':
        ensure  => "3.3.2",
        path    => "/var/www/woolie-co-uk",
        domain  => "woolie.co.uk",
        backups => true,
    }
}
