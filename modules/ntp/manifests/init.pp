class ntp {
    package { "tzdata":
        ensure => latest
    }
    file { "/etc/timezone":
        require => Package["tzdata"],
        source => "puppet:///modules/ntp/timezone",
        notify => Exec['tzdata-reconfigure']
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
        logoutput => true
    }

    package { "ntp":
        ensure => latest
    }
    file { "/etc/ntp.conf":
        mode    => "644",
        source => 'puppet:///modules/ntp/ntp.conf',
        notify  => Service["ntp"],
        require => Package["ntp"],
    }
    service { "ntp":
        ensure  => running,
        enable  => true,
        require => Package["ntp"],
    }
}
