class influx::telegraf {
    include influx::repos

    package { 'telegraf':
        ensure => installed,
        require => Apt::Source['influxdb']
    } ->
    base::addusertogroup { 'Allow telgraf access to Wooldrige PKI certificates':
        ensure => 'exists',
        username => 'telegraf',
        groupname => 'wooldrigepkicertaccess',
        require => [Group['wooldrigepkicertaccess']]
    } ->
    file { '/etc/telegraf/telegraf.conf':
        source  => 'puppet:///modules/influx/telegraf/telegraf.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Service['telegraf']
    } ->
    file { '/etc/telegraf/telegraf.d/woolie-plugins.conf':
        source  => 'puppet:///modules/influx/telegraf/woolie-plugins.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Service['telegraf']
    } ->
    file { '/etc/telegraf/telegraf.d/raspi-temps.conf':
        source  => 'puppet:///modules/influx/telegraf/raspi-temps.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Service['telegraf']
    } ->
    file { '/etc/telegraf/telegraf.d/output-to-websh1.conf':
        source  => 'puppet:///modules/influx/telegraf/output-to-websh1.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Service['telegraf']
    } ->
    file { '/etc/systemd/system/telegraf.service.d':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    } ->
    file { '/etc/systemd/system/telegraf.service.d/10-opts.conf':
        source => 'puppet:///modules/influx/telegraf/10-opts.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify => [Exec['daemon-reload'], Service['telegraf']],
    } ->
    service { 'telegraf':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        enable     => true
    }
}
