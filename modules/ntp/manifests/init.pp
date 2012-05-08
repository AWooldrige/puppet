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

    cron { 'ntp-kick' :
        command => "/usr/bin/ntpq -np | /bin/grep '^\\*' > /dev/null || ( /usr/bin/ntpq -np ; /etc/init.d/ntp restart )",
        user    => 'root',
        ensure  => present,
        minute  => 0,
        require => Package['ntp']
    }
}
