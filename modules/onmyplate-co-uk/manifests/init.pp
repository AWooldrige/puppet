class onmyplate-co-uk {

    $wp_id = 'ompcouk'

    wordpress::instance { $wp_id:
        ensure  => "3.5",
        domain  => "onmyplate.co.uk",
        backups => true,
        http_port => 81
    }

    wordpress::plugin { [ "${wp_id}:akismet",
                          "${wp_id}:livefyre-comments",
                          "${wp_id}:google-analytics-for-wordpress",
                          "${wp_id}:google-sitemap-generator" ]:
        ensure => 'installed',
        active => true,
        require => Wordpress::Instance[$wp_id]
    }

    wordpress::plugin { "${wp_id}:disqus-comment-system":
        ensure => "removed",
        require => Wordpress::Instance[$wp_id]
    }
}
