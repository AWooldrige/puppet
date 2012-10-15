class varnish ($varnish_port=80,
               $httpd_http_host='127.0.0.1',
               $httpd_http_port=81) {

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
