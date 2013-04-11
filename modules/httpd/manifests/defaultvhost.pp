class httpd::defaultvhost () {

    file { '/var/www/default':
        ensure  => directory,
        source  => 'puppet:///modules/httpd/default',
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0700',
        recurse => true,
        purge   => true,
        force   => true,
        require => Package['apache2']
    }
    file { '/etc/apache2/sites-available/default':
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0400',
        content => template('httpd/vhosts/default'),
        notify  => Service['apache2'],
        require => [ File['/var/www/default'], Package['apache2'] ]
    }
    httpd::site { 'default':
        ensure => enabled
    }
}
