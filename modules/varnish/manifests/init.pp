class varnish {
    $httpd_http_host = extlookup('varnish/httpd_http_host')
    $httpd_http_port = extlookup('httpd/http_port')
    $varnish_port = extlookup('varnish/port')

    package { "varnish":
        ensure => installed
    }

    file { "/etc/varnish/default.vcl":
        owner => "root",
        group => "root",
        mode  => '400',
        require => Package["varnish"],
        notify  => Service["varnish"],
        content => template("varnish/default.vcl")
    }

    file { "/etc/default/varnish":
        owner => "root",
        group => "root",
        mode  => '400',
        require => Package["varnish"],
        notify  => Service["varnish"],
        content => template("varnish/service-script")
    }

    service { "varnish":
        ensure  => running,
        enable  => true,
        hasrestart => true,
        require => Package['varnish']
    }
}
