class influx::repos {

    include apt

    # URL fetches rewrote the key each run, bumping mtime and re-triggering apt update
    file { '/etc/apt/keyrings/influxdb.asc':
        ensure => file,
        source => 'puppet:///modules/influx/influxdata-archive.key',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    # InfluxData lag behind new Ubuntu releases, so pin to jammy on 24.04/26.04 (the .deb is codename-agnostic)
    # older hosts (22.04, Raspbian 11) use their real codename for armhf coverage.
    $influx_release = $facts['os']['release']['major'] ? {
        '22.04' => 'jammy',
        '11'    => 'bullseye',
        default => 'jammy',
    }

    apt::source { 'influxdb':
        ensure   => 'present',
        comment  => 'InfluxData repository (telegraf, influxdb)',
        location => 'https://repos.influxdata.com/debian',
        release  => $influx_release,
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
