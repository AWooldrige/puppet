<?php
/*
Plugin Name: WordPress Thumbnail CLI tools
Plugin URI: https://github.com/AWooldrige/puppet
Description: CLI management of WordPress media thumbnails using wpcli
Version: 0.1.0
Author: Alistair Wooldrige
Author URI: http://woolie.co.uk
License: GPLv2 or later

WordPress doesn't provide a mechanism to regenerate thumbnails if the list of
sizes changes.
 */

define('WP_THUMBAILS_PLUGIN_VERSION', '0.1.0');
define('WP_THUMBAILS_PLUGIN_URL', plugin_dir_url( __FILE__ ));

 /**
 *
 * @package wp-cli
 * @subpackage commands/community
 * @maintainer Alistair Wooldrige (http://woolie.co.uk)
*/
class Thumbnails_Command extends WP_CLI_Command {
    /**
     * Lists sizes available to WordPress posts
     */
    function sizes() {
        $image_sizes = get_intermediate_image_sizes();

        foreach($image_sizes as $size_name => $size_attrs) {
        }
        //WP_CLI::success( 'Hello world!' );
    }

    public static function help() {
        WP_CLI::line( <<<EOB
usage: wp thumbnails [sizes|regenerate|purge|clean]

Available sub-commands:
    sizes        lists available configured thumbnail sizes
    generate     generates thumbnails for any sizes that haven't already been processed
    regenerate   Refresh entire library. Calls 'purge' and then 'generate'
    purge        Removes all thumbnails, leaving just originals
    clean        garbage collect thumbnails which are no longer referenced to
EOB
    );
    }
}

WP_CLI::add_command( 'thumbnails', 'Thumbnails_Command' );
