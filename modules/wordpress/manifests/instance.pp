# Define: wordpress::instance
#
# Creates everything required for a base WordPress install
#
# Important: the title should be a short name (under X charactes) with no
# special characters
#
# Sample Usage:
# wordpress { 'wooliecouk':
#    ensure => '3.3.2',
#    domain => 'woolie.co.uk'
# }
#
define wordpress::instance (
    $ensure='3.3.2',
    $domain,
    $backups='true',
    $http_port=80,
    $https_port=443,
    $varnish_addr='127.0.0.1',
    $varnish_port=80) {

    $wp_id = "wp_${title}"
    $path = "/var/www/${wp_id}"

    # HTTPD Virtualhost configuration
    file {"/etc/apache2/sites-available/${wp_id}":
        ensure => present,
        owner => 'www-data',
        group => 'www-data',
        mode => '400',
        content => template("wordpress/apache-virtualhost"),
        notify => Service['apache2']
    }
    httpd::site { $wp_id:
        ensure => enabled
    }


    # MySQL Database setup
    $wp_db_host = "localhost"
    $wp_db_pass = generate("/root/getpassword", "${wp_id}_db_pass")

    mysql::db { $wp_id:
        user => $wp_id,
        password => $wp_db_pass,
        host => $wp_db_host,
        grant => ['select_priv', 'insert_priv', 'update_priv', 'delete_priv',
                  'create_priv', 'index_priv', 'alter_priv',
                  'create_tmp_table_priv', 'lock_tables_priv']
    }


    # Install and Update WordPress using SVN
    exec { "wp-install-${wp_id}":
        command => "svn checkout http://core.svn.wordpress.org/tags/${ensure} ${path}",
        creates => "${path}/wp-includes/version.php",
        require => Package['subversion'],
        notify => [ Service['varnish'], Exec['wp-set-permissions'] ],
        path => '/usr/bin'
    }
    exec { "wp-update-${wp_id}":
        cwd => $path,
        command => "wp core update --version=${ensure} && wp core update-db",
        unless => "grep 'wp_version' ${path}/wp-includes/version.php | grep '${ensure}'",
        require => [ Exec["wp-install-${wp_id}"], Package['subversion'] ],
        notify => [ Service['varnish'], Exec['wp-set-permissions'] ],
        path => [ '/usr/bin', '/bin' ]
    }


    # Automatically create the WordPress configuration file
    $wp_unique_auth_key = generate("/root/getpassword", "${wp_id}_unique_auth_key")
    $wp_unique_secure_auth_key  = generate("/root/getpassword", "${wp_id}_unique_secure_auth_key")
    $wp_unique_logged_in_key = generate("/root/getpassword", "${wp_id}_unique_logged_in_key")
    $wp_unique_nonce_key = generate("/root/getpassword", "${wp_id}_unique_nonce_key")
    $wp_unique_auth_salt = generate("/root/getpassword", "${wp_id}_unique_auth_salt")
    $wp_unique_secure_auth_salt = generate("/root/getpassword", "${wp_id}_unique_secure_auth_salt")
    $wp_unique_logged_in_salt = generate("/root/getpassword", "${wp_id}_unique_logged_in_salt")
    $wp_unique_nonce_salt = generate("/root/getpassword", "${wp_id}_unique_nonce_salt")

    file { "${path}/wp-config.php":
        owner => 'www-data',
        group => 'www-data',
        mode  => '440',
        require => [ Exec["wp-install-${wp_id}"], Exec["wp-update-${wp_id}"] ],
        content => template("wordpress/wp-config.php")
    }

    file { [ "${path}/sitemap.xml", "${path}/sitemap.xml.gz" ]:
        ensure => absent,
        require => [ Exec["wp-install-${wp_id}"], Exec["wp-update-${wp_id}"] ]
    }

    # Add a plugin which helps with the Varnish/WordPress integration
    file { "${path}/wp-content/plugins/wp-varnish":
        ensure => directory,
        owner => 'www-data',
        group => 'www-data',
        require => Exec["wp-install-${wp_id}"]
    }
    file { "${path}/wp-content/plugins/wp-varnish/wp-varnish.php":
        owner => 'www-data',
        group => 'www-data',
        mode => '440',
        require =>  File["${path}/wp-content/plugins/wp-varnish"],
        source => 'puppet:///modules/wordpress/wp-varnish.php',
    }
    wordpress::plugin { "${title}:wp-varnish":
        ensure => "installed",
        active => true,
        require => [
            File["${path}/wp-content/plugins/wp-varnish/wp-varnish.php"],
            Exec["wp-install-${wp_id}"],
            Exec["wp-update-${wp_id}"] ],
    }
    wordpress::plugin { [ "${title}:google-analytics-for-wordpress",
                          "${title}:xml-sitemap-feed" ]:
        ensure => "installed",
        active => true,
        require => [ Exec["wp-install-${wp_id}"], Exec["wp-update-${wp_id}"] ]
    }
    wordpress::plugin { [ "${title}:livefyre-comments",
                          "${title}:disqus-comment-system",
                          "${title}:google-sitemap-generator",
                          "${title}:aksimet" ]:
        ensure => "removed",
        require => [ Exec["wp-install-${wp_id}"], Exec["wp-update-${wp_id}"] ]
    }

    #Gaarg, there's no way to change directory in a cron, and running:
    #   /usr/bin/php /var/www/vhost/wp-cron.php doesn't work because the PHP
    # include path isn't set correctly. For this reason, we have to very hackily
    # fire an HTTP request back to ourselves
    cron {"wp-cron-${wp_id}":
        ensure => present,
        command => "/usr/bin/chronic /usr/bin/curl -I http://${domain}/wp-cron.php",
        user => root,
        minute => 0,
        require => Exec["wp-install-${wp_id}"],
    }

    if $backups == true {
        cron {"incremental_backup_${wp_id}":
            ensure => present,
            command => "/usr/bin/chronic /usr/bin/wp-backup backup incremental ${wp_id}",
            user => root,
            hour => 11,
            minute => 0
        }
        cron {"full_backup_${wp_id}":
            ensure => present,
            command => "/usr/bin/chronic /usr/bin/wp-backup backup full ${wp_id}",
            user => root,
            hour => 23,
            minute => 0
        }
    }
}
