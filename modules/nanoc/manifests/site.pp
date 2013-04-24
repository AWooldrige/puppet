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
define nanoc::site ($ensure='installed', $http_port=80, $repo='none') {

    $domain = $title

    file { ["/var/nanoc/content/${domain}",
            "/var/nanoc/nginx-config/${domain}"]:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }
    file { "/etc/nginx/sites-enabled/nanoc-site-${domain}.conf":
        content => template('nanoc/nginx-site-vhost.conf'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Service['nginx'],
        require => Package['nginx']
    }

    if $repo != 'none' {
        $cmd = "/usr/bin/nanoc-site-downloader ${domain} ${repo}"

        exec { "nanoc-site-download-${domain}":
            command   => $cmd,
            creates   => "/var/nanoc/repos/${domain}",
            path      => [ '/usr/bin', '/bin' ],
            require   => File[
                "/var/nanoc/content/${domain}",
                "/var/nanoc/nginx-config/${domain}",
                "/etc/nginx/sites-enabled/nanoc-site-${domain}.conf"],
            logoutput => "on_failure",
            tries     => 3,
            try_sleep => 20,
            timeout   => 600
        }
        cron {"nanoc-site-download-cron-${domain}":
            ensure  => present,
            command => "/usr/bin/chronic ${cmd}",
            user    => root,
            minute  => 20
        }
    }
}
