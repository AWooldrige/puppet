class httpd::purge () {
    package { ['apache2',
               'apache2-mpm-prefork',
               'apache2-mpm-event',
               'apache2-mpm-perchild',
               'apache2-mpm-worker']:
        ensure => purged,
    }

    file { ['/var/log/apache2',
            '/etc/apache2',
            '/etc/logrotate.d/apache2-vhosts',
            '/var/www/default']:
        ensure  => absent,
        recurse => true,
        force   => true,
        require => Package['apache2']
    }
}
