<?php
/*
Plugin Name: Puppet/Varnish Additions
Plugin URI: https://github.com/AWooldrige/puppet
Description: Makes WordPress more Puppet/Varnish friendly.
Version: 0.1.2
Author: Alistair Wooldrige
Author URI: http://woolie.co.uk
License: GPLv2 or later

What does this plugin do:
 * Cache-Control headers:
    * Suitable caching applied to different pages
    * If a theme's name is suffixed with "-dev", then Cache-Control headers will
      be sent to prevent caching in Varnish and in the browser.
 * When a post is modified, it will request that Varnish purge that page, and
   the homepage
 * Removes width and height parameters from image thumbnail HTML
*/

define('WP_VARNISH_PLUGIN_VERSION', '0.1.2');
define('WP_VARNISH_PLUGIN_URL', plugin_dir_url( __FILE__ ));

function add_cache_control_headers() {
    if (is_admin() || (strpos(get_option('template'), '-dev') !== false)) {
        header('Cache-Control: no-cache, no-store, max-age=0, must-revalidate', true);
        return;
    }
    if (is_search() || is_archive()) {
        header('Cache-Control: max-age=20', true);
        if($_SERVER['HTTP_X_VARNISH']) {
            header('X-Varnish-TTL: 3600', true);
        }
        return;
    }
    header('Cache-Control: max-age=60', true);
    if($_SERVER['HTTP_X_VARNISH']) {
        header('X-Varnish-TTL: 432000', true);
    }
}
add_action('wp', 'add_cache_control_headers');

/**
 * Varnish content purging
 */
function wp_varnish_purge_post($post_id) {
    wp_varnish_purge_url(get_permalink($post_id));
    wp_varnish_purge_url(home_url('/'));
}
function wp_varnish_purge_url($url) {
    $url_parts = parse_url($url);
    $purge_url = 'http://'.VARNISH_ADDR.':'.VARNISH_PORT.$url_parts['path'];
    $ch = curl_init($purge_url);
    curl_setopt($ch, CURLOPT_HTTPHEADER, array('Host: '.$url_parts['host']));
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PURGE');
    curl_exec($ch);
    curl_close($ch);
}

//Purge the post and homepage whenever these are triggered
add_action('publish_post', 'wp_varnish_purge_post', 99);
add_action('edit_post', 'wp_varnish_purge_post', 99);
add_action('deleted_post', 'wp_varnish_purge_post', 99);

/**
 * WordPress adds absolute width and height parameters to post thumbnails.
 * Although hacky, this filter strips this on the way out.
 *
 * Source:
 * http://wordpress.stackexchange.com/questions/5568/filter-to-remove-image-dimension-attributes
 *
 * @param post thumbnail html $html
 * @access public
 * @return string filtered html without width or height
 */
function remove_thumbnail_dimensions($html) {
    $html = preg_replace('/(width|height)=\"\d*\"\s/', "", $html);
    return $html;
}
add_filter('post_thumbnail_html', 'remove_thumbnail_dimensions', 10);
add_filter('image_send_to_editor', 'remove_thumbnail_dimensions', 10);

/**
 * The default jpeg quality within WordPress is 90, which is a bit high.
 *
 * @param int $quality jpeg quality
 * @access public
 * @return int new jpeg quality
 */
function jpeg_resize_quality($quality){
    return 70;
}
add_filter('jpeg_quality', 'jpeg_resize_quality');
