class loggly {

    package { 'rsyslog':
        ensure => latest
    }

    file { '/etc/rsyslog.d/loggly.conf':
        source => 'puppet:///modules/loggly/22-loggly.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['rsyslog'],
        notify  => Service['rsyslog']
    }

    service { 'rsyslog':
        ensure => running
    }
}
