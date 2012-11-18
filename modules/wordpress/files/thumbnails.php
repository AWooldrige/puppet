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
     * Generate all thumbnails for sizes that haven't had thumbnails generated
     * for them
     *
     * @access public
     * @return void
     */
    public function generate() {

        self::syncDbToFs();

        $images = self::getImageAttachments();
        $targetSizes = self::getSizes();

        if($images) {
            WP_CLI::line('Generating thumbnails for:');

            foreach($images as $image) {
                $imageMeta = wp_get_attachment_metadata($image->ID);
                $originalPath = get_attached_file($image->ID);

                if(file_exists($originalPath)) {

                    //Could just call wp_generate_attachment_metadata for all images,
                    //but this is a very slow call, even if nothing needs generating
                    foreach($targetSizes as $sizeName => $sizeAttrs) {

                        //There's no point checking which target sizes don't exist,
                        //just regenerate at the first miss
                        if(!array_key_exists($sizeName, $imageMeta['sizes'])) {

                            //TODO: Need to check if the original image size is smaller than the resized,
                            //because at the moment it will try and regenerate every time

                            //TODO: Pull the following out into a static function

                            WP_CLI::line(
                                'Generating "' . $sizeName . '" for - [' .
                                $image->ID . '] ' . $image->post_title . '(' .
                                $originalPath . ')'
                            );

                            $meta = wp_generate_attachment_metadata($image->ID, $originalPath);
                            //print_r($meta);

                            if(is_wp_error($meta)) {
                                WP_CLI::warning(
                                    $meta->get_error_message() .
                                    ' whilst processing image ID '. $image->ID .
                                    ' - ' . $image->post_title
                                );
                            }
                            if(empty($meta)) {
                                WP_CLI::warning(
                                    'Whilst processing image ID ' . $image->ID .
                                    ' - ' . $image->post_title
                                );
                            }

                            wp_update_attachment_metadata($image->ID, $meta);
                            break;
                        }
                    }
                }
                else {
                    WP_CLI::warning(
                        'Could not find original file for image [' . $image->ID .
                        '] %9' . $image->post_title . '%n at ' . $originalPath
                    );
                }
            }
        }
        else {
            WP_CLI::warning('There are no image attachments on this WordPress blog');
        }
    }

    /**
     * Return a list of all intermediate sizes available to themes
     *
     * @access public
     * @return void
     */
    public function sizes() {
        foreach(self::getSizes() as $size_name => $size_attrs) {
            WP_CLI::line(
                ' ' . $size_name . ': %9' . $size_attrs['width'] . '%nx%9' .
                $size_attrs['height'] . '%n'
            );
        }
    }


    /**
     * Return an array containg all intermediate image sizes available to themes.
     *
     * @static
     * @access protected
     * @return array of size names, widths, heights and crop toggles.
     */
    protected static function getSizes() {

        //Construct array for WordPress default sizes
        $sizes = array();
        foreach(array('thumbnail', 'medium', 'large') as $std_size) {
            $sizes[$std_size] = array(
                'width' => intval(get_option($std_size . '_size_w')),
                'height' => intval(get_option($std_size . '_size_h')),
                'crop' => False
            );
        }

        //The size name is 'thumb', but the DB stores the size as 'thumbnail'
        //$sizes['thumb'] = $sizes['thumbnail'];
        //unset($sizes['thumbnail']);

        //Merge with any additional sizes requested by themes
        global $_wp_additional_image_sizes;
        if(isset($_wp_additional_image_sizes) && count($_wp_additional_image_sizes)) {
            $sizes = array_merge($sizes, $_wp_additional_image_sizes);
        }

        return $sizes;
    }

    /**
     * When a resized file is deleted from the filesystem, this is not
     * registered in the database. This command checks all sizes in the database,
     * and removes any entries that do not exist on the FS
     *
     * @static
     * @access protected
     * @return
     */
    protected static function syncDbToFs() {
        $images = self::getImageAttachments();

        if($images) {

            foreach($images as $image) {
                $originalPath = get_attached_file($image->ID);

                if(file_exists($originalPath)) {
                    $imageMeta = wp_get_attachment_metadata($image->ID);
                    $dir = dirname($originalPath);

                    $newSizes = array();
                    foreach($imageMeta['sizes'] as $size_name => $size_attrs) {
                        $resizedFile = $dir . DIRECTORY_SEPARATOR . $size_attrs['file'];
                        if(file_exists($resizedFile) === FALSE) {
                            WP_CLI::line(
                                $resizedFile . ' - not found (%9' . $size_name . 
                                '%n size)');
                        }
                        else {
                            $newSizes[$size_name] = $size_attrs;
                        }
                    }

                    if($newSizes != $imageMeta['sizes']) {
                        $imageMeta['sizes'] = $newSizes;
                        wp_update_attachment_metadata($image->ID, $imageMeta);
                    }
                }
                else {
                    WP_CLI::warning(
                        'Could not find file for image [' . $image->ID .
                        '] %9' . $image->post_title . '%n at ' . $originalPath
                    );
                }
            }
        }


    }

    /**
     * Return all attachments from the database which are images
     *
     * @static
     * @access protected
     * @return array of image attachments
     */
    protected static function getImageAttachments() {
        return get_posts(
            array(
                'post_type' => 'attachment',
                'post_mime_type'  => 'image*',
                'numberposts' => -1,
                'post_status' => null,
                'post_parent' => null
            )
        );
    }
}

WP_CLI::add_command( 'thumbnails', 'Thumbnails_Command' );
