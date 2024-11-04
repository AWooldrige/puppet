class influx::repos {

    include apt

    # Older Ubuntu or Raspbian 11
    if $facts['os']['release']['major'] in ['22.04', '11'] {
        apt::source { 'influxdb':
            ensure => 'present',
            comment => 'InfluxDB packages for TICK stack',
            location => 'https://repos.influxdata.com/debian',
            release => $::lsbdistcodename,
            repos => 'stable',
            key => {
                id => '05CE15085FC09D18E99EFB22684A14CF2582E0C5',
                source => 'https://repos.influxdata.com/influxdb.key'
            },
            include => {
                'src' => false,
                'deb' => true
            },
            notify => Exec['apt_update']
        }
        apt::source { 'grafana':
            ensure => 'present',
            comment => 'Grafana from Grafana Labs',
            location => 'https://packages.grafana.com/oss/deb',
            release => 'stable',
            repos => 'main',
            key => {
                id => '4E40DDF6D76E284A4A6780E48C8C34C524098CB6',
                source => 'https://packages.grafana.com/gpg.key'
            },
            include => {
                'src' => false,
                'deb' => true
            },
            notify => Exec['apt_update']
        }
    }
    else {
        apt::source{ 'influxdb':
            comment  => 'Influx data repos',
            location => 'https://repos.influxdata.com/debian',
            repos    => 'stable',

            # This is horrible, but for some reason Influx don't have a repo
            # for 24.04 (noble) yet. Forcing to 22.04 LTS (jammy) seems to work
            # ok, so using that as a workaround for now. Delete this entire
            # release line and let apt::source use the default when this is
            # fixed. https://github.com/influxdata/telegraf/issues/16007
            release => 'jammy',

            key      => {
                'name'   => 'influxdb.asc',
                'source' => 'https://repos.influxdata.com/influxdata-archive.key',
            },
            notify => Exec['apt_update']
        }
    }
}
