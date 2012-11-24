class diamond (
    $graphite_host = 'mon1.woolie.co.uk',
    $graphite_port = 2003,
    $polling_interval = 60) {

    $pkg = 'diamond_3.0.2_all.deb'

    exec { 'download-diamond-pkg':
        command => "curl -L -o /opt/local-debs/${pkg} https://github.com/downloads/AWooldrige/puppet/${pkg}",
        creates => "/opt/local-debs/${pkg}",
        require => File['/opt/local-debs']
    }

    package { ["sysstat", "python-support", "python-configobj"]:
        ensure => installed
    }

    package { 'diamond':
        provider => dpkg,
        ensure => latest,
        source => "/opt/local-debs/${pkg}",
        require => [
            File['/opt/local-debs'],
            Package['python-support'],
            Package['python-configobj'],
            Package['sysstat'],
            Exec['download-diamond-pkg'] ]
    }

    file { '/etc/diamond/diamond.conf':
        ensure => present,
        owner => 'root',
        group => 'root',
        mode => 644,
        content => template('diamond/diamond.conf.erb'),
        notify => Service['diamond'],
        require => Package['diamond']
    }
    file { '/etc/init/diamond.conf':
        ensure => present,
        owner => 'root',
        group => 'root',
        mode => 644,
        content => template('diamond/diamond.upstart.conf.erb'),
        notify => Service['diamond'],
        require => Package['diamond']
    }

    $collectors_conf = '/etc/diamond/collectors'

    file { "${collectors_conf}/UserScriptsCollector.conf":
        ensure => present,
        owner => 'root',
        group => 'root',
        mode => 400,
        content => template('diamond/UserScriptsCollector.conf.erb'),
        notify => Service['diamond'],
        require => Package['diamond']
    }

    file { ["${collectors_conf}/CPUCollector.conf",
            "${collectors_conf}/DiskSpaceCollector.conf",
            "${collectors_conf}/DiskUsageCollector.conf",
            "${collectors_conf}/LoadAverageCollector.conf",
            "${collectors_conf}/MemoryCollector.conf",
            "${collectors_conf}/NetworkCollector.conf",
            "${collectors_conf}/SockstatCollector.conf",
            "${collectors_conf}/TCPCollector.conf",
            "${collectors_conf}/InterruptCollector.conf",
            "${collectors_conf}/FilestatCollector.conf",
            "${collectors_conf}/VMStatCollector.conf"]:
        ensure => present,
        owner => 'root',
        group => 'root',
        mode => 644,
        content => 'enabled = True',
        notify => Service['diamond'],
        require => Package['diamond']
    }
    service { 'diamond':
        ensure => running,
        provider => upstart,
        require => [
            Package['diamond'],
            File['/etc/diamond/diamond.conf'],
            File['/etc/init/diamond.conf']
            ]
    }
}
