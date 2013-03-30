class wp::knck {

    $wp_id = 'knck'

    wordpress::instance { $wp_id:
        ensure              => '3.5.1',
        domain              => 'kempstonnurseries.co.uk',
        google_analytics_id => 'UA-?-?',
        backups             => true,
        http_port           => 81
    }
    wordpress::defaults { $wp_id: }

    wordpress::option { "${wp_id}:permalink_structure":
        ensure => present,
        value => '/%category%/%postname%'
    }
}
