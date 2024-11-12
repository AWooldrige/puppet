class prometheus {
    package { 'prometheus':
        ensure => installed
    }

    file { '/etc/default/prometheus':
        source  => 'puppet:///modules/prometheus/prometheus_args',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['prometheus'],
        notify  => Service['prometheus']
    }
    file { '/etc/prometheus/prometheus.yml':
        source  => 'puppet:///modules/prometheus/prometheus.yml',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['prometheus'],
        notify  => Service['prometheus']
    }

    service { 'prometheus':
        ensure     => running,
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        require   => [
            File['/etc/default/prometheus'],
            File['/etc/prometheus/prometheus.yml']
        ]
    }
    service { [
            'prometheus-node-exporter',
            'prometheus-node-exporter-apt',
            'prometheus-node-exporter-nvme',
        ]:
        ensure => stopped,
        enable => false,
        require => Package['prometheus']
    }
}
