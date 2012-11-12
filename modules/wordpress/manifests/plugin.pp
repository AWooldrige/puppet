# Define: wordpress::plugin
#
# Orchestrates adding a plugin to a specific WordPress installation. Because
# each title must be unique in puppet, the title must include both the
# WordPress instance id, and plugin name. It is important to check the
# WordPress instance id, as this determines where the plugin is installed.
#
# Example: using a plugin from the WordPress plugin repo
#     wordpress::plugin { ['wooliecouk:akismet', 'wooliecouk:jetpack' ]:
#        ensure =>  'installed',
#     }
#
# Example: using a local zip of a plugin, but not activating
#     wordpress::plugin { 'wooliecouk:omp-plugin':
#        ensure =>  'installed',
#        source => '/opt/local-zips/omp-plugin.zip',
#        active => false
#     }
#
define wordpress::plugin($ensure, $active=true, $source_file=false) {

    $plugin_name = regsubst($title, '(.*):(.*)', '\2')
    $wordpress_id = regsubst($title, '(.*):(.*)', '\1')

    $wp_id = "wp_${wordpress_id}"
    $wp_path = "/var/www/${wp_id}"
    $plugin_path = "${wp_path}/wp-content/plugins/${plugin_name}"

    if $ensure == 'installed' {

        #Work out correct argument to wp plugin install command
        if $source_file != false {
            $arg = $source_file
        }
        else {
            $arg = $theme_name
        }

        exec { "wp-plugin-install-${title}":
            cwd => $wp_path,
            command => "wp plugin install ${arg}",
            path => [ '/usr/bin', '/bin' ],
            creates => $plugin_path,
            notify => [ Service['varnish'], Exec['wp-set-permissions'] ]
        }

        if $active == true {
            exec { "wp-plugin-activate-${title}":
                cwd => $wp_path,
                command => "wp plugin activate ${plugin_name}",
                unless => "wp plugin status ${plugin_name} | grep 'Status.*Active'",
                path => [ '/usr/bin', '/bin' ],
                require => Exec["wp-plugin-install-${title}"],
                notify => [ Service['varnish'], Exec['wp-set-permissions'] ]
            }
        }
        else {
            exec { "wp-plugin-deactivate-${title}":
                cwd => $wp_path,
                command => "wp plugin deactivate ${plugin_name}",
                unless => "wp plugin status ${plugin_name} | grep 'Status.*Inactive'",
                path => [ '/usr/bin', '/bin' ],
                require => Exec["wp-plugin-install-${title}"],
                notify => [ Service['varnish'], Exec['wp-set-permissions'] ]
            }
        }
    }
    if $ensure == 'removed' {
        exec { "wp-plugin-remove-${title}":
            cwd => $wp_path,
            command => "wp plugin uninstall ${plugin_name}",
            onlyif => "[ -d ${plugin_path} ]",
            path => [ '/usr/bin', '/bin' ],
            notify => [ Service['varnish'], Exec['wp-set-permissions'] ]
        }
    }
}
