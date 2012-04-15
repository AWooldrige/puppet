# Class: wordpress
#
# This module manages wordpress
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
# wordpress { 'woolie.co.uk':
#    ensure  =>  "3.3.1",
#    path    => "/var/www/woolie-co-uk/",
#    domain  => "woolie.co.uk",
#    backups => false
# }
#
# [Remember: No empty lines between comments and class definition]

class wordpress {
}

define wordpress::instance (
    $ensure = '3.3.1',
    $path,
    $domain,
    $backups = 'false') {

    package{ 'subversion':
        ensure => 'latest'
    }

    $safe_domain = regsubst($domain, '\.', '_', 'G')
    $wp_db_prefix  = "wp_"
    $wp_db_name    = "${wp_db_prefix}${safe_domain}"
    $wp_db_user    = "wp_${safe_domain}"
    $wp_db_host    = "localhost"
    $wp_db_pass    = generate("/root/getpassword", "wp_${safe_domain}")
    $wp_unique_auth_key         = generate("/root/getpassword", "wp_${safe_domain}_unique_auth_key")
    $wp_unique_secure_auth_key  = generate("/root/getpassword", "wp_${safe_domain}_unique_secure_auth_key")
    $wp_unique_logged_in_key    = generate("/root/getpassword", "wp_${safe_domain}_unique_logged_in_key")
    $wp_unique_nonce_key        = generate("/root/getpassword", "wp_${safe_domain}_unique_nonce_key")
    $wp_unique_auth_salt        = generate("/root/getpassword", "wp_${safe_domain}_unique_auth_salt")
    $wp_unique_secure_auth_salt = generate("/root/getpassword", "wp_${safe_domain}_unique_secure_auth_salt")
    $wp_unique_logged_in_salt   = generate("/root/getpassword", "wp_${safe_domain}_unique_logged_in_salt")
    $wp_unique_nonce_salt       = generate("/root/getpassword", "wp_${safe_domain}_unique_nonce_salt")



    # TODO: Exec to set permissions for wordpress files
    # TODO: Need to manage the wp conf


    if $ensure == 'purged' {

        # rm -rf the $path only if a wordpress file is there
        exec { "wp-purge":
            command => "/bin/rm -rf ${path}",
            onlyif  => "/usr/bin/[ -e ${path}/wp-includes/version.php ]",
        }

    }
    else {

        # exec svn checkout onlyif wordpress file doesn't exist
        exec { "wp-install":
            command => "/usr/bin/svn checkout http://core.svn.wordpress.org/tags/${ensure} ${path}",
            creates => "${path}/wp-includes/version.php",
            require => Package['subversion'],
            notify  => [ Exec["wp-set-permissions"],
                         File["${path}/wp-config.php"] ]
        }

        mysql::db { $wp_db_name:
            user     => $wp_db_user,
            password => $wp_db_pass,
            host     => $wp_db_host,
            grant    => ['select_priv', 'insert_priv', 'update_priv',
                         'delete_priv', 'create_priv', 'index_priv',
                         'alter_priv', 'create_tmp_table_priv',
                         'lock_tables_priv']
        }

        # exec svn update only if the file exists and the version number doesn't match $ensure
        exec { "wp-update":
            command => "/usr/bin/svn sw http://core.svn.wordpress.org/tags/${ensure} ${path}",
            onlyif  => [ "/usr/bin/[ -f ${path}/wp-includes/version.php ]",
                         "/bin/bash -c \"/usr/bin/[ `/bin/grep 'wp_version =' ${path}/wp-includes/version.php | cut -d\' -f2` != ${ensure} ]\"" ],
            require => Package['subversion'],
            notify  => [ Exec["wp-set-permissions"],
                         File["${path}/wp-config.php"] ]
        }

        # Ensure permissions are set correctly for files
        exec { "wp-set-permissions":
            command => "/usr/bin/find ${path} -type d -exec /bin/chmod 750 {} \\;; /usr/bin/find ${path} -type d -exec /bin/chmod 640 {} \\;; /bin/chown -R www-data:www-data ${path}",
            onlyif  => "/usr/bin/[ -f ${path}/wp-includes/version.php ]"
        }

        file { "${path}/wp-config.php":
            owner   => 'www-data',
            group   => 'www-data',
            mode    => '400',
            content => template("wordpress/wp-config.php")
        }

    }
}
