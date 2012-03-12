class mysql () {
    $mysql_root_password = extlookup('mysql/mysql_root_password')

    package { "mysql-server":
        ensure => latest
    }

    exec { "mysql_root_password":
        subscribe => Package["mysql-server"],
        refreshonly => true,
        unless => "mysqladmin -uroot -p$mysql_root_password status",
        path => "/bin:/usr/bin",
        command => "mysqladmin -uroot password $mysql_root_password",
    }

    file { "/etc/mysql/my.cnf":
        owner   => 'root',
        group   => 'root',
        mode    => '444',
        require => Package['mysql-server'],
        content => template("mysql/my.cnf"),
        notify  => Service['mysql']
    }
    service { "mysql":
        ensure => running,
        hasstatus => true,
        hasrestart => true,
        require => File["/etc/mysql/my.cnf"],
        restart => true
    }
}
