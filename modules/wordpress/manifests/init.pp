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
# Title should be a short name
# wordpress { 'wooliecouk':
#    ensure  =>  "3.3.2",
#    path    => "/var/www/woolie-co-uk/",
#    domain  => "woolie.co.uk",
#    backups => false
# }
#
# [Remember: No empty lines between comments and class definition]

class wordpress {
    package{ 'subversion':
        ensure => 'installed'
    }
    file { '/usr/bin/wp-set-permissions':
        source => 'puppet:///modules/wordpress/wp-set-permissions',
        owner => 'root',
        group => 'root',
        mode => '540'
    }

    file { '/etc/wp-backup':
        ensure => 'directory',
        owner => 'root',
        group => 'root'
    }
    file { '/usr/bin/wp-backup':
        source => 'puppet:///modules/wordpress/wp-backup',
        owner => 'root',
        group => 'root',
        mode => '540'
    }


}

define wordpress::instance (
    $ensure = '3.3.2',
    $path,
    $domain,
    $backups = 'false') {

    $underscore_domain = regsubst($domain, '\.', '_', 'G')
    $wp_db_prefix  = "wp_"
    $wp_db_name    = "${wp_db_prefix}${title}"
    $wp_db_user    = "${wp_db_prefix}${title}"
    $wp_db_host    = "localhost"
    $wp_db_pass    = generate("/root/getpassword", "wp_${underscore_domain}")
    $wp_unique_auth_key         = generate("/root/getpassword", "wp_${underscore_domain}_unique_auth_key")
    $wp_unique_secure_auth_key  = generate("/root/getpassword", "wp_${underscore_domain}_unique_secure_auth_key")
    $wp_unique_logged_in_key    = generate("/root/getpassword", "wp_${underscore_domain}_unique_logged_in_key")
    $wp_unique_nonce_key        = generate("/root/getpassword", "wp_${underscore_domain}_unique_nonce_key")
    $wp_unique_auth_salt        = generate("/root/getpassword", "wp_${underscore_domain}_unique_auth_salt")
    $wp_unique_secure_auth_salt = generate("/root/getpassword", "wp_${underscore_domain}_unique_secure_auth_salt")
    $wp_unique_logged_in_salt   = generate("/root/getpassword", "wp_${underscore_domain}_unique_logged_in_salt")
    $wp_unique_nonce_salt       = generate("/root/getpassword", "wp_${underscore_domain}_unique_nonce_salt")

    $http_port = extlookup('httpd/http_port')
    $https_port = extlookup('httpd/https_port')

    if $ensure == 'purged' {

        # rm -rf the $path only if a wordpress file is there
        exec { "wp-purge-${underscore_domain}":
            command => "/bin/rm -rf ${path}",
            onlyif  => "/usr/bin/[ -e ${path}/wp-includes/version.php ]",
        }

        # ensure apache entries are removed
        file {"/etc/apache2/sites-available/${underscore_domain}":
            ensure  => absent
        }
        httpd::site { $underscore_domain:
            ensure => disabled
        }

        # remove the cron jobs
        cron {"incremental_backup_wp_content_${underscore_domain}":
            ensure => absent
        }
        cron {"incremental_backup_wp_mysql_${underscore_domain}":
            ensure => absent
        }

        # Remove logrotate
        file {"/etc/logrotate.d/wp_${title}":
            ensure  => absent
        }
    }
    else {

        file {"/var/log/apache2/${underscore_domain}":
            ensure  => directory,
            owner   => 'www-data',
            group   => 'www-data',
            mode    => '750',
            require => Package['apache2']
        }
        file {"/etc/apache2/conf.d/sites/${underscore_domain}/_null.conf":
            ensure  => present,
            owner   => 'www-data',
            group   => 'www-data',
            mode    => '400',
            content => '#Directory for snippets to be included in the HTTP virtualhost',
            require => Httpd::Site["${underscore_domain}"],
            notify  => Service['apache2']
        }
        file {"/etc/apache2/sites-available/${underscore_domain}":
            ensure  => present,
            owner   => 'www-data',
            group   => 'www-data',
            mode    => '400',
            content => template("wordpress/apache-virtualhost"),
            require => [ Package['apache2'],
                         File["/var/log/apache2/${underscore_domain}"] ],
            notify  => Service['apache2'],
        }

        file {"/etc/logrotate.d/wp_${title}":
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '400',
            content => template("wordpress/logrotate-template")
        }

        httpd::site { $underscore_domain:
            ensure => enabled,
            require => File["/etc/apache2/sites-available/${underscore_domain}"]
        }

        # exec svn checkout onlyif wordpress file doesn't exist
        exec { "wp-install-${underscore_domain}":
            command => "/usr/bin/svn checkout http://core.svn.wordpress.org/tags/${ensure} ${path}",
            creates => "${path}/wp-includes/version.php",
            require => Package['subversion'],
            notify  => [ Exec["wp-set-permissions-${underscore_domain}"],
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
        exec { "wp-update-${underscore_domain}":
            command => "/usr/bin/svn sw http://core.svn.wordpress.org/tags/${ensure} ${path}",
            onlyif  => [ "/usr/bin/[ -f ${path}/wp-includes/version.php ]",
                         "/bin/bash -c \"/usr/bin/[ `/bin/grep 'wp_version =' ${path}/wp-includes/version.php | cut -d\' -f2` != ${ensure} ]\"" ],
            require => Package['subversion'],
            notify  => [ Exec["wp-set-permissions-${underscore_domain}"],
                         File["${path}/wp-config.php"] ]
        }

        # Ensure permissions are set correctly for files
        exec { "wp-set-permissions-${underscore_domain}":
            command => "/usr/bin/wp-set-permissions ${path}",
            onlyif  => "/usr/bin/[ -f ${path}/wp-includes/version.php ]",
            require => [File['/usr/bin/wp-set-permissions'], Exec["wp-install-${underscore_domain}"]],
            refreshonly => true
        }

        cron {"wp-set-permissions-${title}":
            ensure => present,
            command => "/usr/bin/wp-set-permissions ${path}",
            user => root,
            hour => 2,
            minute => 30
        }

        file { "${path}/wp-config.php":
            owner   => 'www-data',
            group   => 'www-data',
            mode    => '440',
            require => Exec["wp-install-${underscore_domain}"],
            content => template("wordpress/wp-config.php")
        }

        file { "${path}/wp-content/plugins/wpvp-plugin.php":
            owner   => 'www-data',
            group   => 'www-data',
            mode    => '440',
            require => Exec["wp-install-${underscore_domain}"],
            source => 'puppet:///modules/wordpress/wpvp-plugin.php',
        }

        $identifier       = $title
        $destination_path = extlookup('backup/path')
        $local_wp_path    = $path

        file {"/etc/wp-backup/${title}":
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '440',
            content => template("wordpress/backup-config"),
            require => File['/etc/wp-backup']
        }

        if $backups == true {
            cron {"incremental_backup_${title}":
                ensure => present,
                command => "/usr/bin/wp-backup incremental ${title}",
                user => root,
                hour => 4,
                minute => 0
            }
        }
        else {
            cron {"incremental_backup_${title}":
                ensure => absent
            }
        }
    }
}
