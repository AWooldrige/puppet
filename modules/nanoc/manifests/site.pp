# Define: nanoc::site
#
# Creates a base for a nanoc site
#
# Important: the title should be the domain name. E.g. 'woolie.co.uk', not
#            'www.woolie.co.uk', 'http://woolie.co.uk'
#
# Sample Usage:
# nanoc::site { 'wooliecouk':
#    ensure => installed
# }
#
define nanoc::site ($ensure='installed', $http_port=80) {

    $domain = $title

    file { "/var/nanoc-sites/${domain}":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }
    file { "/etc/nginx/sites-enabled/nanoc-site-${domain}.conf":
        content => template('nanoc/nginx-site-vhost.conf'),
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify  => Service['nginx'],
        require  => Package['nginx']
    }
}
