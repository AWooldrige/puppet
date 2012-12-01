class onmyplate-co-uk {

    $wp_id = 'ompcouk'

    wordpress::instance { $wp_id:
        ensure  => "3.4.2",
        domain  => "onmyplate.co.uk",
        backups => true,
        http_port => 81
    }

    wordpress::plugin { [ "${wp_id}:akismet",
                          "${wp_id}:disqus-comment-system",
                          "${wp_id}:google-analytics-for-wordpress",
                          "${wp_id}:google-sitemap-generator" ]:
        ensure => 'installed',
        active => true,
        require => Wordpress::Instance[$wp_id]
    }
}
