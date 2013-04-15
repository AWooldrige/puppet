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

    file { "/var/log/nginx/nanoc-sites/${domain}":
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755'
    }
    file { "/var/nanoc-sites/${domain}":
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755'
    }
    file { "/etc/nginx/conf.d/nanoc-sites/${domain}.conf":
        content => template('nanoc/nginx-site-vhost.conf'),
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0644',
        notify  => Service['nginx'],
        require  => Service['nginx']
    }
}
