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
        ensure => 'installed'
    }

    $underscore_domain = regsubst($domain, '\.', '_', 'G')
    $wp_db_prefix  = "wp_"
    $wp_db_name    = "${wp_db_prefix}${underscore_domain}"
    $wp_db_user    = "wp_${underscore_domain}"
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
        exec { "wp-purge":
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
    }
    else {

        file {"/var/log/apache2/${underscore_domain}":
            ensure  => directory,
            owner   => 'www-data',
            group   => 'www-data',
            mode    => '750',
            require => Package['apache2']
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

        httpd::site { $underscore_domain:
            ensure => enabled,
            require => File["/etc/apache2/sites-available/${underscore_domain}"]
        }

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
            command => "/usr/bin/wp-set-permissions ${path}",
            onlyif  => "/usr/bin/[ -f ${path}/wp-includes/version.php ]",
            require => File['/usr/bin/wp-set-permissions'],
            refreshonly => true
        }

        file { '/usr/bin/wp-set-permissions':
            source => 'puppet:///modules/wordpress/wp-set-permissions',
            owner => 'root',
            group => 'root',
            mode => '540'
        }

        file { "${path}/wp-config.php":
            owner   => 'www-data',
            group   => 'www-data',
            mode    => '440',
            content => template("wordpress/wp-config.php")
        }


        if $backups == true {
            $incr_bkp_host = extlookup('backup/host')
            $incr_bkp_location = extlookup('backup/location')
            $tmp_path = "/tmp/puppet/wordpress"
            $mysql_tmp_path = "${tmpPath}/wordpress/${underscore_domain}/mysql"

            if($incr_bkp_host == 'filesystem') {
                $command =  "/usr/bin/rdiff-backup --create-full-path ${path}/wp-content ${incr_bkp_location}/wordpress/${underscore_domain}/wp-content"
            }
            else {
                $command =  "/usr/bin/rdiff-backup --create-full-path ${path}/wp-content ${incr_bkp_host}:${incr_bkp_location}/wordpress/${underscore_domain}/wp-content"
            }

            cron {"incremental_backup_wp_content_${underscore_domain}":
                ensure => present,
                command => $command,
                user => root,
                hour => 4
            }

            if($incr_bkp_host == 'filesystem') {
                $command2 = "/bin/rm -rf ${mysql_tmp_path};\
/bin/mkdir -p ${mysql_tmp_path};\
/usr/bin/mysqldump ${wp_db_name} > ${mysql_tmp_path}/${wp_db_name}.sql;\
/usr/bin/rdiff-backup --create-full-path ${mysql_tmp_path} ${incr_bkp_location}/wordpress/${underscore_domain}/mysql;\
/bin/rm -rf ${mysql_tmp_path};"
            }
            else {
                $command2 = "/bin/rm -rf ${mysql_tmp_path};\
/bin/mkdir -p ${mysql_tmp_path};\
/usr/bin/mysqldump ${wp_db_name} > ${mysql_tmp_path}/${wp_db_name}.sql;\
/usr/bin/rdiff-backup --create-full-path ${mysql_tmp_path} ${incr_bkp_host}:${incr_bkp_location}/wordpress/${underscore_domain}/mysql;\
/bin/rm -rf ${mysql_tmp_path};"
            }

            cron {"incremental_backup_wp_mysql_${underscore_domain}":
                ensure => present,
                command => $command2,
                user => root,
                hour => 3
            }
        }
    }
}
