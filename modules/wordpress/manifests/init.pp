# Class: wordpress
#
# Installs all neccessary dependancies and shared configuration/code for
# subsequent wordpress::instance(s)
#
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

    file { '/usr/bin/wp-backup':
        source => 'puppet:///modules/wordpress/wp-backup',
        owner => 'root',
        group => 'root',
        mode => '540'
    }

    httpd::module { [ 'rewrite', 'expires', 'ssl', 'alias', 'headers',
        'authz_host' ]:
        ensure => enabled
    }

    file {"/etc/logrotate.d/wordpress_instances":
        source => 'puppet:///modules/wordpress/logrotate',
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '644',
    }

    file {"/etc/wp-backup.conf":
        ensure => present,
        owner => 'root',
        group => 'root',
        mode => '440',
        content => template("wordpress/backup-config")
    }

    pear::package { "wpcli":
        repository => "wp-cli.org/pear"
    }
}
