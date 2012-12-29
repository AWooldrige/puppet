class onmyplate-co-uk {

    $wp_id = 'ompcouk'

    wordpress::instance { $wp_id:
        ensure  => "3.5",
        domain  => "onmyplate.co.uk",
        backups => true,
        http_port => 81
    }
}
