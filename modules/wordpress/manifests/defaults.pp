# Define: wordpress::defaults
#
# Sets up default plugins and options for a WordPress instance
#
define wordpress::defaults() {

    $wp_id = "wp_${title}"

    wordpress::plugin { "${title}:wp-varnish":
        ensure  => installed,
        active  => true
    }
    wordpress::plugin { "${title}:xml-sitemap-feed":
        ensure  => installed,
        active  => true
    }
    wordpress::plugin { [
            "${title}:google-analytics-for-wordpress",
            "${title}:livefyre-comments",
            "${title}:disqus-comment-system",
            "${title}:google-sitemap-generator",
            "${title}:aksimet"]:
        ensure  => removed
    }

    wordpress::option { "${title}:users_can_register":
        ensure => present,
        value  => '0'
    }
    wordpress::option { "${title}:timezone_string":
        ensure => present,
        value  => 'Europe/London'
    }
    wordpress::option { "${title}:time_format":
        ensure => present,
        value  => 'g:i a'
    }
}
