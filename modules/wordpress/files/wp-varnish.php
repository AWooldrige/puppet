<?php
/*
Plugin Name: Puppet/Varnish Additions
Plugin URI: https://github.com/AWooldrige/puppet
Description: Makes WordPress more Puppet/Varnish friendly.
Version: 0.1.0
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

define('WP_VARNISH_PLUGIN_VERSION', '0.1.0');
define('WP_VARNISH_PLUGIN_URL', plugin_dir_url( __FILE__ ));

//If we're on a development theme, don't cache anything!
if (strpos(get_option('template'), '-dev') !== false) {
    header('Cache-Control: no-cache, no-store, max-age=0, must-revalidate', true);
}
