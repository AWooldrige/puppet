class varnish ($varnish_port=80,
               $httpd_http_host='127.0.0.1',
               $httpd_http_port=81) {

    package { "varnish":
        ensure => installed
    }

    file { "/etc/varnish/default.vcl":
        ensure => absent
    }

    file { "/etc/varnish/main.vcl":
        source => 'puppet:///modules/varnish/main.vcl',
        owner => "root",
        group => "root",
        mode  => '644',
        require => Package["varnish"],
        notify  => Service["varnish"]
    }
    file { "/etc/varnish/backends.vcl":
        content => template("varnish/backends.vcl.erb"),
        owner => "root",
        group => "root",
        mode  => '644',
        require => Package["varnish"],
        notify  => Service["varnish"]
    }
    file { "/etc/varnish/acl.vcl":
        content => template("varnish/acl.vcl.erb"),
        owner => "root",
        group => "root",
        mode  => '644',
        require => Package["varnish"],
        notify  => Service["varnish"]
    }

    file { "/etc/default/varnish":
        owner => "root",
        group => "root",
        mode  => '644',
        require => Package["varnish"],
        notify  => Service["varnish"],
        content => template("varnish/service-script")
    }

    file { "/usr/share/diamond/user_scripts/varnish_metrics":
        source => 'puppet:///modules/varnish/varnish_metrics',
        owner => "root",
        group => "root",
        mode  => '744',
        require => Package["diamond"],
        notify  => Service["diamond"]
    }

    service { "varnish":
        ensure  => running,
        enable  => true,
        hasrestart => true,
        require => Package['varnish']
    }
}
