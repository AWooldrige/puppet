# Define: httpd::site
#
# Uses Ubuntu's (Debian's) a2ensite method to enable sites. This expects a vhost
# configuration file to be at /etc/apache2/sites-available/[vhostname]. It also
# creates a log directory for the vhost, with correct logrotation covering it
# within /var/log/apache2/vhost/[vhostname]
#
define httpd::site($ensure = 'enabled') {
    if $title == 'default' {
        $enabled = '000-default'
    } else {
        $enabled = $title
    }

    case $ensure {
        'enabled' : {
            exec { "/usr/sbin/a2ensite ${title}":
                unless => "/bin/sh -c '[ -f /etc/apache2/sites-enabled/${enabled} ]'",
                notify => Exec["force-reload-apache2"],
                require => [ File["/etc/apache2/sites-available/${title}"], Package['apache2'] ]
            }
        }
        'disabled': {
            exec { "/usr/sbin/a2dissite $title":
                onlyif => "/bin/sh -c '[ -f /etc/apache2/sites-enabled/${enabled} ]'",
                notify => Exec["force-reload-apache2"],
                require => Package['apache2']
            }
        }
        default: { err ( "Unknown ensure value: '$ensure'" ) }
    }

    file {"/etc/apache2/conf.d/sites/${title}":
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '750',
        require => Package['apache2']
    }
    file { "/var/log/apache2/vhost/${title}":
        ensure => directory,
        owner => 'www-data',
        group => 'www-data',
        mode => '750',
        require => File['/var/log/apache2/vhost']
    }
}
