<?php
/**
 * WordPress doesn't provide a mechanism to regenerate thumbnails if the list of
 * sizes changes.
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
            WP_CLI::line(
                $size_name . ': ' . $size_attrs['width'] . 'x' .
                $size_attrs['height'] . ' - cropping' . $size_attrs['crop']
            )
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
