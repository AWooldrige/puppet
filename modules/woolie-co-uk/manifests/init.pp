class woolie-co-uk {

    $wp_id = 'wooliecouk'

    $themezip = 'old-wooliecouk-theme.zip'
    exec { "download-${themezip}-theme":
        command => "curl -L -o /opt/local-zips/${themezip} https://github.com/downloads/AWooldrige/puppet/${themezip}",
        creates => "/opt/local-zips/${themezip}",
        require => File['/opt/local-zips']
    }


    wordpress::instance { $wp_id:
        ensure  => "3.4.2",
        domain  => "woolie.co.uk",
        backups => true,
        http_port => 81
    }

    wordpress::plugin { [ "${wp_id}:akismet",
                          "${wp_id}:disqus-comment-system",
                          "${wp_id}:google-analytics-for-wordpress",
                          "${wp_id}:google-sitemap-generator",
                          "${wp_id}:wp-syntax" ]:
        ensure => 'installed',
        active => true,
        require => Wordpress::Instance[$wp_id]
    }

    wordpress::theme { "${wp_id}:woolie.co.uk":
        ensure => 'installed',
        active => true,
        source_file => "/opt/local-zips/${themezip}",
        require => [ Wordpress::Instance[$wp_id], Exec["download-${themezip}-theme"] ]
    }
}
