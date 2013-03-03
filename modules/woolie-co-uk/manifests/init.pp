class woolie-co-uk {

    $wp_id = 'wooliecouk'

    $theme_version = '0.1.1'
    exec { "download-${wp_id}-theme-${theme_version}":
        command => "curl -L -o /opt/local-zips/${wp_id}-theme-${theme_version}.zip https://s3-eu-west-1.amazonaws.com/woolie-releases/wp_${wp_id}/${wp_id}-theme-${theme_version}.zip",
        creates => "/opt/local-zips/${wp_id}-theme-${theme_version}.zip",
        require => File['/opt/local-zips']
    }

    wordpress::instance { $wp_id:
        ensure  => "3.5.1",
        domain  => "woolie.co.uk",
        backups => true,
        http_port => 81
    }

    wordpress::plugin { "${wp_id}:wp-syntax":
        ensure => "installed",
        active => true,
        require => Wordpress::Instance[$wp_id]
    }

    wordpress::theme { "${wp_id}:${wp_id}-theme-${theme_version}":
        ensure => 'installed',
        active => true,
        source_file => "/opt/local-zips/${wp_id}-theme-${theme_version}.zip",
        require => [
            Wordpress::Instance[$wp_id],
            Exec["download-${wp_id}-theme-${theme_version}"] ]
    }
}
