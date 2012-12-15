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
 * If a theme's name is suffixed with "-dev", then Cache-Control headers will
   be sent to prevent caching in Varnish and in the browser.

*/

/*
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
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
