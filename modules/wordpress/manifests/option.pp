# Define: wordpress::option
#
# Allows WordPress database options to be set
#
# Example: Stopping user registrations
#    wordpress::option { "wp_ompcouk:users_can_register":
#        ensure => present,
#        value => '0'
#    }
#
define wordpress::option($ensure, $value=False) {

    $option = regsubst($title, '(.*):(.*)', '\2')
    $wordpress_id = regsubst($title, '(.*):(.*)', '\1')

    $wp_id = "wp_${wordpress_id}"
    $wp_path = "/var/www/${wp_id}"

    if $ensure == 'present' {
        exec { "wp-option-present-${title}":
            cwd => $wp_path,
            command => "wp option set ${option} ${value}",
            unless => "[ $(wp option get ${option}) = '${value}' ]",
            path => [ '/usr/bin', '/bin' ],
            require => Exec['wpcli-install'],
            notify => Service['varnish']
        }
    }
}
