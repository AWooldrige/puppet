class onmyplate-co-uk () {
    wordpress::instance {'onmyplate.co.uk':
        ensure  => "3.3.2",
        path    => "/var/www/onmyplate-co-uk",
        domain  => "onmyplate.co.uk",
        backups => true,
    }
}
