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
    require nanoc
    require nanoc::compiler

    $domain = $title

    $document_root = "/var/nanoc/content/${domain}"
    $config_root = "/var/nanoc/nginx-config/${domain}"

    file { [$document_root, $config_root]:
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
    file { "/etc/rsyslog.d/nanoc-${domain}.conf":
        content => template('nanoc/rsyslog.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['rsyslog'],
        notify  => Service['rsyslog']
    }

    if $repo != 'none' {
        $log_file = "/var/log/nanoc-site-downloader"
        $cmd = "/usr/bin/nanoc-site-downloader ${domain} ${repo}"

        exec { "nanoc-site-download-${domain}":
            command   => $cmd,
            creates   => "/var/nanoc/repos/${domain}",
            path      => [ '/usr/bin', '/bin', '/usr/local/bin' ],
            require   => File[
                $document_root,
                $config_root,
                "/etc/nginx/sites-enabled/nanoc-site-${domain}.conf"],
            logoutput => "true",
            tries     => 3
        }
        cron {"nanoc-site-download-cron-${domain}":
            ensure  => present,
            command => "/usr/bin/chronic ${cmd}",
            user    => root,
            minute  => [0, 15, 30, 45]
        }
    }
    else {
        file { "${document_root}/index.html":
            source => 'puppet:///modules/nanoc/coming-soon.html',
            ensure => present,
            owner  => 'www-data',
            group  => 'www-data',
            mode   => '0644'
        }
    }
}
