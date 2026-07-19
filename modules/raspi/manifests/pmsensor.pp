class raspi::pmsensor {

    $venv = '/opt/pmsensor-venv'

    exec {"telegraf dialout":
        provider => 'shell',
        unless => '/usr/bin/groups telegraf | /usr/bin/grep dialout',
        command => '/usr/sbin/usermod -a -G dialout telegraf',
        require => Package['telegraf']
    }

    package { 'python3-venv':
        ensure => installed,
    } ->
    exec { 'Create pmsensor venv':
        command => "/usr/bin/python3 -m venv ${venv}",
        creates => "${venv}/bin/python3",
    } ->
    exec { 'Install sds011 into pmsensor venv':
        command  => "${venv}/bin/pip install sds011",
        unless   => "${venv}/bin/python3 -c 'import sds011'",
        provider => 'shell',
    } ->
    file { '/usr/bin/pmsensor':
        source => 'puppet:///modules/raspi/pmsensor/pmsensor',
        owner  => 'root',
        group  => 'root',
        mode   => '755'
    } ->
    file { '/etc/telegraf/telegraf.d/pmsensor.conf':
        source => 'puppet:///modules/raspi/pmsensor/pmsensor.telegraf.conf',
        owner => 'root',
        group => 'root',
        mode  => '0644',
        require => Package['telegraf'],
        notify => Service['telegraf']
    }
}
