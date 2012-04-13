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
    $db_name    = "wp_${safe_domain}"
    $db_user    = "wp_${safe_domain}"
    $db_host    = "localhost"

    file { $path:
        ensure => directory,
        purge => false,
        recurse => false,
        owner => "www-data",
        group => "www-data",
        mode => 0640
    }


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
            require => [ Package['subversion'],
                         File[$path] ]
        }

        mysql::db { $db_name:
            user     => $db_user,
            password => generate("/root/getpassword", "wp_${safe_domain}"),
            host     => $db_host,
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
            require => [ Package['subversion'],
                         File[$path] ]
        }

    }
}
