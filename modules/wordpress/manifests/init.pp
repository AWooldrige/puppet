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
    exec { 'wp-set-permissions':
        command => "/usr/bin/wp-set-permissions /var/www/wp_*",
        require => File['/usr/bin/wp-set-permissions'],
        refreshonly => true
    }
    cron {'wp-set-permissions':
        ensure => present,
        command => "/usr/bin/wp-set-permissions /var/www/wp_*",
        user => root,
        hour => 2,
        minute => 30
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

    # Very annoying, can't use the pear module, as a bug prevents the repository
    # from containing forward slashes. A pull has been requested for a fix, but
    # not yet been merged
    #pear::package { "wpcli":
    #    repository => "wp-cli.org/pear"
    #}
    exec { 'wpcli-install':
        command => 'pear channel-discover wp-cli.org/pear; pear update-channels;pear install wpcli/wpcli;',
        path => ['/bin', '/usr/bin'],
        require => Package['php-pear'],
        unless => 'pear list -c wpcli && pear list -c wpcli | grep wpcli'
    }

    # thumbnails wpcli command
    file { "/usr/share/php/wp-cli/commands/community/thumbnails.php":
        source => 'puppet:///modules/wordpress/thumbnails.php',
        ensure => present,
        owner => 'root',
        group => 'root',
        mode => '644',
        require => Exec["wpcli-install"]
    }
}
