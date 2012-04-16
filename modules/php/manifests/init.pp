class php {

    package { ["libapache2-mod-php5", "php5-mysql"]:
        ensure => installed
    }

    file { "/etc/php5/apache2/php.ini":
        owner => "root",
        group => "root",
        mode  => '400',
        require => Package["libapache2-mod-php5"],
        notify  => Service['apache2']
    }
}
