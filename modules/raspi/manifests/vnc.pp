class raspi::vnc {
    package { 'x11vnc':
        ensure => installed
    }
    file { '/home/pi/.xsessionrc':
        source  => 'puppet:///modules/raspi/xsessionrc',
        owner   => 'pi',
        group   => 'pi',
        mode    => '0755',
        require => Package['x11vnc']
    }
}
class raspi::vnc::remove {
    package { 'x11vnc':
        ensure => absent
    }
    file { '/home/pi/.xsessionrc':
        ensure => absent
    }
}
