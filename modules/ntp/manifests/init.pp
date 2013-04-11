class ntp {
    package { 'tzdata':
        ensure => installed
    }
    file { '/etc/timezone':
        content => 'Europe/London',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['tzdata'],
        notify  => Exec['tzdata-reconfigure']
    }
    exec { 'tzdata-reconfigure':
        refreshonly => true,
        command     => 'dpkg-reconfigure -f noninteractive tzdata',
        path        => [
            '/usr/local/bin',
            '/opt/local/bin',
            '/usr/bin',
            '/usr/sbin',
            '/bin',
            '/sbin' ]
    }

    package { 'ntp':
        ensure => installed
    }
    file { '/etc/ntp.conf':
        source  => 'puppet:///modules/ntp/ntp.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['ntp']
    }
    service { 'ntp':
        ensure  => running,
        enable  => true,
        require => [ Package['ntp'], File['/etc/ntp.conf'] ]
    }

    file { '/usr/bin/ntp-kick':
        source => 'puppet:///modules/ntp/ntp-kick',
        owner  => 'root',
        group  => 'root',
        mode   => '744'
    }
    cron { 'ntp-kick' :
        command => '/usr/bin/chronic /usr/bin/ntp-kick',
        user    => 'root',
        ensure  => present,
        minute  => 0,
        hour    => 5,
        require => [ Service['ntp'], File['/usr/bin/ntp-kick'] ]
    }
}
