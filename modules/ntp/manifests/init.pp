class ntp {
    package { "tzdata":
        ensure => installed
    }
    file { "/etc/timezone":
        owner   => 'root',
        group   => 'root',
        mode    => '644',
        require => Package["tzdata"],
        source => "puppet:///modules/ntp/timezone",
        notify => Exec['tzdata-reconfigure'],
    }
    exec { 'tzdata-reconfigure':
        command => 'dpkg-reconfigure -f noninteractive tzdata',
        path => [
            '/usr/local/bin',
            '/opt/local/bin',
            '/usr/bin',
            '/usr/sbin',
            '/bin',
            '/sbin'],
        refreshonly => true
    }

    package { "ntp":
        ensure => installed
    }
    file { "/etc/ntp.conf":
        owner   => 'root',
        group   => 'root',
        mode    => '644',
        source => 'puppet:///modules/ntp/ntp.conf',
        notify  => Service["ntp"],
        require => Package["ntp"],
    }
    service { "ntp":
        ensure  => running,
        enable  => true,
        require => Package["ntp"],
    }

    file { '/usr/bin/ntp-kick':
        source => 'puppet:///modules/ntp/ntp-kick',
        owner => 'root',
        group => 'root',
        mode => '544'
    }
    cron { 'ntp-kick' :
        command => "/usr/bin/chronic /usr/bin/ntp-kick",
        user    => 'root',
        ensure  => present,
        minute  => 0,
        hour  => 5,
        require => [ Package['ntp'], File['/usr/bin/ntp-kick'] ]
    }
}
