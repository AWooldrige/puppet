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
