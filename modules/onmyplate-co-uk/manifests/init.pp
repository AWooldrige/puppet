class onmyplate-co-uk () {
    wordpress::instance {'ompcouk':
        ensure  => "3.3.2",
        domain  => "onmyplate.co.uk",
        backups => true,
        http_port => 81
    }
}
