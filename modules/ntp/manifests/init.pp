class ntp {

    service { 'systemd-timesyncd':
        ensure => stopped,
        enable => false
    }

    package { 'chrony':
        ensure => installed
    }

    file { '/etc/chrony/sources.d':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package['chrony']
    }

    file { '/etc/chrony/sources.d/woolie-ntp.sources':
        source  => 'puppet:///modules/ntp/woolie-ntp.sources',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => [ Package['chrony'], File['/etc/chrony/sources.d'] ],
        notify  => Service['chrony']
    }

    service { 'chrony':
        ensure  => running,
        enable  => true,
        require => File['/etc/chrony/sources.d/woolie-ntp.sources']
    }

    exec { 'Set correct timezone':
        command  => "timedatectl set-timezone Europe/London",
        unless   => "timedatectl status | grep 'Time zone: Europe/London'",
        provider => "shell"
    }
}
