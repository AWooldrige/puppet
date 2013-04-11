# Define: httpd::module
#
# Uses Ubuntu's (Debian's) a2enmod method to enable modules.
#
define httpd::module($ensure = 'enabled') {
    case $ensure {
        'enabled' : {
            exec { "/usr/sbin/a2enmod ${title}":
                unless  => "/bin/sh -c '[ -L /etc/apache2/mods-enabled/${title}.load ] \\
                    && [ /etc/apache2/mods-enabled/${title}.load -ef /etc/apache2/mods-available/${title}.load ]'",
                notify  => Service['apache2'],
                require => Package['apache2']
            }
        }
        'disabled': {
            exec { "/usr/sbin/a2dismod ${title}":
                onlyif  => "/bin/sh -c '[ -L /etc/apache2/mods-enabled/${title}.load ] \\
                    && [ /etc/apache2/mods-enabled/${title}.load -ef /etc/apache2/mods-available/${title}.load ]'",
                notify  => Service['apache2'],
                require => Package['apache2']
            }
        }
        default: { err ( "Unknown ensure value: '${ensure}'" ) }
    }
}
