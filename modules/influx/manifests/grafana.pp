class influx::grafana {
    include influx::repos

    package { 'grafana':
        ensure => installed,
        require => [
            Apt::Source['grafana'],
            Class['apt::update']
        ]
    } ->
    file { "/etc/grafana/grafana.ini":
        source => 'puppet:///modules/influx/grafana.ini',
        owner => 'root',
        group => 'grafana',
        mode => '0644',
        notify => Service['grafana-server']
    } ->
    service { 'grafana-server':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        enable     => true
    }

    file { "/etc/nginx/cg.wooldrige.co.uk.d/grafana.conf":
        source => 'puppet:///modules/influx/grafana-nginx.conf',
        owner => 'root',
        group => 'root',
        mode => '0644',
        require => File["/etc/nginx/cg.wooldrige.co.uk.d"],
        notify => Service['nginx']
    }
}
