class httpd {
    package { "apache2":
        ensure => latest
    }

/*
    package { ["apache2-mpm-event", "apache2-mpm-perchild", "apache2-mpm-prefork"]:
        ensure => absent,
    }
    file { "/etc/apache2/conf.d/fqdn":
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '644',
        require => Package['apache2'],
        content => template("httpd/conf.d/fqdn"),
        notify  => Service['apache2']
    }
    file { "/etc/apache2/apache2.conf":
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '644',
        require => Package['apache2'],
        content => template("httpd/apache2.conf"),
        notify  => Service['apache2']
    }
    file { "/etc/apache2/ports.conf":
        ensure => absent
    }
    service { "apache2":
        ensure  => running,
        enable  => true,
        hasrestart => true,
        require => Package['apache2'],
    }


    exec { "reload-apache2":
        command => "/etc/init.d/apache2 reload",
        refreshonly => true,
        before => [ Service["apache2"], Exec["force-reload-apache2"] ]
    }
    exec { "force-reload-apache2":
        command => "/etc/init.d/apache2 force-reload",
        refreshonly => true,
        before => Service["apache2"],
    }



    define module ( $ensure = 'present') {
        case $ensure {
            'enabled' : {
                exec { "/usr/sbin/a2enmod $name":
                    unless => "/bin/sh -c '[ -L ${apache_mods}-enabled/${name}.load ] \\
                        && [ ${apache_mods}-enabled/${name}.load -ef ${apache_mods}-available/${name}.load ]'",
                    notify => Exec["force-reload-apache2"],
                }
            }
            '': {
                exec { "/usr/sbin/a2dismod $name":
                    onlyif => "/bin/sh -c '[ -L ${apache_mods}-enabled/${name}.load ] \\
                        && [ ${apache_mods}-enabled/${name}.load -ef ${apache_mods}-available/${name}.load ]'",
                    notify => Exec["force-reload-apache2"],
                }
            }
            default: { err ( "Unknown ensure value: '$ensure'" ) }
        }
  }
*/
}
