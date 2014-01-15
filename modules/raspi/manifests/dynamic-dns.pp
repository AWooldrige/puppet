class raspi::dynamic-dns {
    package { 'python-dnspython':
        ensure => installed
    }
    file { '/usr/bin/update-dynamic-dns':
        source  => 'puppet:///modules/raspi/update-dynamic-dns',
        owner   => 'root',
        group   => 'root',
        mode    => '0755'
    }
    cron {"update-dynamic-dns":
        ensure  => present,
        command => "/usr/bin/chronic /usr/bin/update-dynamic-dns",
        user    => root,
        minute  => [0, 10, 20, 30, 40, 50]
    }
}
