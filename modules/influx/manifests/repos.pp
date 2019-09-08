
class influx::repos {

    include apt

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

}
