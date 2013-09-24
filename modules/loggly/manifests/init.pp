#Stolen from https://github.com/grahamlyons/puppet/blob/master/modules/loggly/manifests/init.pp
class loggly {

    package { 'rsyslog':
        ensure => latest
    }

    file { '/etc/rsyslog.d/loggly.conf':
        content => '*.*    @@logs.loggly.com:31145',
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
