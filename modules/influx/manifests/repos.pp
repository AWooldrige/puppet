class influx::repos {

    include apt

    file { '/etc/apt/keyrings/influxdb.asc':
        ensure => file,
        source => 'puppet:///modules/influx/influxdata-archive.key',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    apt::source { 'influxdb':
        ensure   => 'present',
        comment  => 'InfluxData repository (telegraf, influxdb)',
        location => 'https://repos.influxdata.com/debian',
        # InfluxData lag behind Ubuntu releases and the .deb is codename-agnostic.
        release  => 'jammy',
        repos    => 'stable',
        keyring  => '/etc/apt/keyrings/influxdb.asc',
        include  => {
            'src' => false,
            'deb' => true,
        },
        require  => File['/etc/apt/keyrings/influxdb.asc'],
        notify   => Exec['apt_update'],
    }
}
