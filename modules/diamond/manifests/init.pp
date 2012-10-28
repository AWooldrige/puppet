class diamond (
    $graphite_host = 'mon1.woolie.co.uk',
    $graphite_port = 2003,
    $polling_interval = 60) {

    $pkg = 'diamond_3.0.2_all.deb'

    exec { 'download-diamond-pkg':
        command => "curl -o /opt/local-debs/${pkg} http://github.com/downloads/AWooldrige/puppet/${pkg}",
        creates => "/opt/local-debs/${pkg}"
    }

    package { ["python-support", "python-configobj"]:
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
            Exec['download-diamond-pkg'] ]
    }

    file { '/etc/diamond/diamond.conf':
        ensure => present,
        owner => 'root',
        group => 'root',
        mode => 400,
        content => template('diamond/diamond.conf.erb'),
        notify => Service['diamond'],
        require => Package['diamond']
    }
    file { '/etc/diamond/collectors/UserScriptsCollector.conf':
        ensure => present,
        owner => 'root',
        group => 'root',
        mode => 400,
        content => template('diamond/UserScriptsCollector.conf.erb'),
        notify => Service['diamond'],
        require => Package['diamond']
    }

    service { 'diamond':
        ensure => running,
        enable => true,
        provider => upstart,
        require => [
            Package['diamond'],
            File['/etc/diamond/diamond.conf']]
    }
}
