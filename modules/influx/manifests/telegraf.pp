class influx::telegraf {

    package { 'telegraf':
        ensure => installed,
        require => Apt::Source['influxdb']
    } ->
    file { '/etc/telegraf/telegraf.conf':
        source  => 'puppet:///modules/influx/telegraf/telegraf.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['telegraf'],
        notify  => Service['telegraf']
    } ->
    file { '/etc/telegraf/telegraf.d/woolie-plugins.conf':
        source  => 'puppet:///modules/influx/telegraf/woolie-plugins.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['telegraf'],
        notify  => Service['telegraf']
    } ->
    file { '/etc/telegraf/telegraf.d/raspi-temps.conf':
        source  => 'puppet:///modules/influx/telegraf/raspi-temps.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['telegraf'],
        notify  => Service['telegraf']
    } ->
    service { 'telegraf':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        enable     => true
    }
}
