class woolie-co-uk () {
    wordpress::instance {'wooliecouk':
        ensure  => "3.3.2",
        domain  => "woolie.co.uk",
        backups => true,
        http_port => 81
    }
}
