class wp::bbcom {

    $wp_id = 'bbcom'

    wordpress::instance { $wp_id:
        ensure              => '3.5.1',
        domain              => 'brignellbookbinders.com',
        google_analytics_id => 'UA-29516594-1',
        backups             => true,
        http_port           => 81
    }

    wordpress::defaults { $wp_id: }

    wordpress::option { "${wp_id}:permalink_structure":
        ensure => present,
        value  => '/%year%/%monthnum%/%day%/%postname%/'
    }
}
