class woolie-co-uk {

    $wp_id = 'wooliecouk'

    wordpress::instance { $wp_id:
        ensure  => "3.3.2",
        domain  => "woolie.co.uk",
        backups => true,
        http_port => 81
    }

    wordpress::plugin { "${wp_id}:akismet":
        ensure => 'installed',
        require => Wordpress::Instance[$wp_id]
    }
}
