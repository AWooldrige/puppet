class raspi::dynamic-dns {
    package { 'python-dnspython':
        ensure => installed
    }
    package { 'pystun':
        ensure   => installed,
        provider => pip
    }
    file { '/usr/bin/update-dynamic-dns':
        source  => 'puppet:///modules/raspi/update-dynamic-dns',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => [ Package['pystun'], Package['python-dnspython'] ]
    }
    cron {"update-dynamic-dns":
        ensure  => present,
        command => "/usr/bin/chronic /usr/bin/update-dynamic-dns",
        user    => root,
        minute  => [0, 10, 20, 30, 40, 50],
        require => File['/usr/bin/update-dynamic-dns']
    }
    cron {"update-dynamic-dns-at-boot":
        ensure  => present,
        command => "/usr/bin/chronic /usr/bin/update-dynamic-dns",
        user    => root,
        special => 'reboot',
        require => File['/usr/bin/update-dynamic-dns']
    }
}
