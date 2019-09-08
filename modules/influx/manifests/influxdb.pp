class influx::influxdb {
    include influx::repos

    package { 'influxdb':
        ensure => installed,
        require => Apt::Source['influxdb']
    } ->
    file { '/etc/influxdb/influxdb.conf':
        source  => 'puppet:///modules/influx/influxdb.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644'
    } ->
    service { 'influxdb':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        enable     => true
    }
}
