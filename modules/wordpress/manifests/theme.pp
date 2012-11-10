# Define: wordpress::theme
#
# Orchestrates adding a theme to a specific WordPress installation. Because
# each title must be unique in puppet, the title must include both the
# WordPress instance id, and theme name. It is important to check the
# WordPress instance id, as this determines where the theme is installed.
#
# Example: using a theme from the WordPress theme repo
#     wordpress::theme { ['wooliecouk:twentyeleven', 'wooliecouk:twentyten' ]:
#        ensure =>  'installed',
#     }
#
# Example: using a local zip of a theme, and activating
#     wordpress::theme { 'ompcouk:omp-theme':
#        ensure =>  'installed',
#        source => '/opt/local-zips/omp-theme.zip',
#        active => true
#     }
#
define wordpress::theme($ensure, $active=false, $source_file=false) {

    $theme_name = regsubst($title, '(.*):(.*)', '\2')
    $wordpress_id = regsubst($title, '(.*):(.*)', '\1')

    $wp_id = "wp_${wordpress_id}"
    $wp_path = "/var/www/${wp_id}"
    $theme_path = "${wp_path}/wp-content/themes/${theme_name}"

    if $ensure == 'installed' {

        #Work out correct argument to wp theme install command
        if $source_file != false {
            $arg = $source_file
        }
        else {
            $arg = $theme_name
        }

        exec { "wp-theme-install-${title}":
            cwd => $wp_path,
            command => "wp theme install ${arg}",
            path => [ '/usr/bin', '/bin' ],
            creates => $theme_path,
            notify => [ Service['varnish']]
        }

        if $active == true {
            exec { "wp-theme-activate-${title}":
                cwd => $wp_path,
                command => "wp theme activate ${theme_name}",
                unless => "wp theme status ${theme_name} | grep 'Status.*Active'",
                path => [ '/usr/bin', '/bin' ],
                require => Exec["wp-theme-install-${title}"]
            }
        }
        else {
            exec { "wp-theme-deactivate-${title}":
                cwd => $wp_path,
                command => "wp theme deactivate ${theme_name}",
                unless => "wp theme status ${theme_name} | grep 'Status.*Inactive'",
                path => [ '/usr/bin', '/bin' ],
                require => Exec["wp-theme-install-${title}"]
            }
        }
    }
    if $ensure == 'removed' {
        exec { "wp-theme-remove-${title}":
            cwd => $wp_path,
            command => "wp theme uninstall ${theme_name}",
            onlyif => "[ -d ${theme_path} ]",
            path => [ '/usr/bin', '/bin' ],
        }
    }
}
