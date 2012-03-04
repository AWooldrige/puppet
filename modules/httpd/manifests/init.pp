class httpd ($http_port, $https_port) {

    package { [ "apache2", "apache2-mpm-prefork" ]:
        ensure => latest
    }
    package { ["apache2-mpm-event", "apache2-mpm-perchild", "apache2-mpm-worker"]:
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
    file { "/etc/apache2/conf.d/ports.conf":
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '644',
        require => Package['apache2'],
        content => template("httpd/conf.d/ports.conf"),
        notify  => Service['apache2']
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
}

define httpd::module($ensure = 'enabled') {
    case $ensure {
        'enabled' : {
            exec { "/usr/sbin/a2enmod $title":
                unless => "/bin/sh -c '[ -L /etc/apache2/mods-enabled/${name}.load ] \\
                    && [ /etc/apache2/mods-enabled/${name}.load -ef /etc/apache2/mods-available/${name}.load ]'",
                notify => Exec["force-reload-apache2"],
            }
        }
        'disabled': {
            exec { "/usr/sbin/a2dismod $title":
                onlyif => "/bin/sh -c '[ -L /etc/apache2/mods-enabled/${name}.load ] \\
                    && [ /etc/apache2/mods-enabled/${name}.load -ef /etc/apache2/mods-available/${name}.load ]'",
                notify => Exec["force-reload-apache2"],
            }
        }
        default: { err ( "Unknown ensure value: '$ensure'" ) }
    }
}
