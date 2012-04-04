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
# wordpress {
#    ensure  =>  3.3.1,
#    path    => "/var/www/woolie-co-uk/"
#    domain  => "woolie.co.uk"
#    backups => false
# }
#
# [Remember: No empty lines between comments and class definition]
define wordpress(
    $ensure = '3.3.1',
    $path,
    $domain,
    $backups = 'false') {

    package{ 'subversion':
        ensure => 'latest'
    }

    if $ensure == 'purged'

        # rm -rf the $path only if a wordpress file is there
        exec { "purge":":
            command => "/bin/rm -rf ${path}",
            onlyif  => "/usr/bin/[ -e ${path}wp-includes/version.php ]",
        }

    else

        # exec svn checkout onlyif wordpress file doesn't exist
        exec { "install":":
            command => "/usr/bin/svn checkout http://core.svn.wordpress.org/tags/${ensure} ${path}",
            creates => "${path}wp-includes/version.php",
            require => Package['subversion']
        }

        # exec svn update only if the file exists and the version number doesn't match $ensure
        exec { "update":":
            command => "/usr/bin/svn sw http://core.svn.wordpress.org/tags/${ensure} ${path}",
            onlyif  => "/usr/bin/[ -e ${path}wp-includes/version.php ]",
            unless  => "/bin/bash -c \"/usr/bin/[ `/bin/grep 'wp_version =' ${path}wp-includes/version.php | cut -d\' -f2` = ${ensure} ]\"",
            require => Package['subversion']
        }

    end
}
