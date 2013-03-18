<?php
/*
Plugin Name: Puppet/Varnish Additions
Plugin URI: https://github.com/AWooldrige/puppet
Description: Makes WordPress more Puppet/Varnish friendly.
Version: 0.1.3
Author: Alistair Wooldrige
Author URI: http://woolie.co.uk
License: GPLv2 or later

What does this plugin do:
 * When a post is modified, it will request that Varnish purge that page, and
   the homepage
 * Removes width and height parameters from image thumbnail HTML
 * Rewrites https urls to admin.

#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
*/

define('WP_VARNISH_PLUGIN_VERSION', '0.1.3');
define('WP_VARNISH_PLUGIN_URL', plugin_dir_url( __FILE__ ));

/**
 * Varnish content purging
 */
function wp_varnish_purge_post($post_id) {
    wp_varnish_purge_url(get_permalink($post_id));
    wp_varnish_purge_url(home_url('/'));
    wp_varnish_purge_url(home_url('/sitemap.xml'));
}
function wp_varnish_purge_url($url) {
    $url_parts = parse_url($url);
    $purge_url = 'http://'.VARNISH_ADDR.':'.VARNISH_PORT.$url_parts['path'];
    $ch = curl_init($purge_url);
    curl_setopt($ch, CURLOPT_HTTPHEADER, array('Host: '.$url_parts['host']));
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PURGE');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    curl_exec($ch);
    curl_close($ch);
}
add_action('publish_post', 'wp_varnish_purge_post', 99);
add_action('edit_post', 'wp_varnish_purge_post', 99);
add_action('deleted_post', 'wp_varnish_purge_post', 99);


/**
 * The default jpeg quality within WordPress is 90, which is a bit high.
 *
 * @param int $quality jpeg quality
 * @access public
 * @return int new jpeg quality
 */
function jpeg_resize_quality($quality){
    return 75;
}
add_filter('jpeg_quality', 'jpeg_resize_quality');
add_filter('wp_editor_set_quality', 'jpeg_resize_quality');


/**
 * Swap out the current site domain with {@see SSL_DOMAIN_ALIAS} if the
 * protocol is HTTPS.
 *
 * This function was inspired by the one written by TheDeadMedic:
 * http://wordpress.stackexchange.com/questions/38902
 *
 * @param string $url the URL to possibly use SSL alias for
 * @return string the possibly SSL version of the URL
 */
function _use_ssl_domain_alias_for_https($url) {
    $domain = parse_url(WP_SITEURL, PHP_URL_HOST);
    $pattern = '/^https\:\/\/'.$domain.'/';
    if (preg_match($pattern, $url) === 1) {
        $url = str_replace($domain, SSL_DOMAIN_ALIAS, $url);
    }
    return $url;
}
add_filter('plugins_url', '_use_ssl_domain_alias_for_https', 1);
add_filter('content_url', '_use_ssl_domain_alias_for_https', 1);
add_filter('site_url', '_use_ssl_domain_alias_for_https', 1);


/**
 * There are plugins available for doing this, but they all seem bloated
 * for the simple job that they should be doing. This also means the GA ID can
 * be configured in puppet rather than manually in the DB
 */
function insertGoogleAnalytics() {

    if(defined('GOOGLE_ANALYTICS_ID')) {
        $ga = '';
        $ga .= '<script type="text/javascript">';

        $ga .= '  var _gaq = _gaq || [];';
        $ga .= "  _gaq.push(['_setAccount', '".GOOGLE_ANALYTICS_ID."']);";
        $ga .= "  _gaq.push(['_trackPageview']);";
        $ga .= '  (function() {';
        $ga .= "    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;";
        $ga .= "    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';";
        $ga .= "    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);";
        $ga .= '  })();';
        $ga .= '</script>';

        echo $ga;
    }
}
add_action('wp_head', 'insertGoogleAnalytics', 99999);
