class raspi::piface {
    package { ['python-pifacedigitalio', 'python3-pifacedigitalio']:
        ensure => installed
    }
    file { '/etc/modprobe.d/raspi-blacklist.conf':
        source  => 'puppet:///modules/raspi/raspi-blacklist.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0400'
    }
}
