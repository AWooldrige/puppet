class grafana {
    include grafana::repos

    package { 'grafana':
        ensure => installed,
        require => [
            Apt::Source['grafana'],
            Class['apt::update']
        ]
    } ->
    file { "/etc/grafana/grafana.ini":
        source => 'puppet:///modules/grafana/grafana.ini',
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

    exec { 'Allow nginx access to grafana socket':
        unless => '/bin/grep -q "grafana\\S*www-data" /etc/group',
        command => '/sbin/usermod -aG grafana www-data',
        require => [Package['nginx'], Package['grafana']]
    }

    file { "/etc/nginx/h.wooldrige.co.uk.d/grafana.conf":
        source => 'puppet:///modules/grafana/grafana-nginx.conf',
        owner => 'root',
        group => 'root',
        mode => '0644',
        require => File["/etc/nginx/h.wooldrige.co.uk.d"],
        notify => Service['nginx']
    }

    file { '/usr/local/sbin/backup-grafana':
        source => 'puppet:///modules/grafana/backup-grafana',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }
    cron { 'Backup grafana daliy':
        ensure  => present,
        command => '/usr/bin/systemd-cat -t "backup-grafana" /usr/local/sbin/backup-grafana',
        hour => [3],
        minute => 5,  # Offset from gdpup runs as the backup will stop the systemd service temporarily
        require => [
            File['/usr/local/sbin/backup-grafana'],
            Service['grafana-server']
        ]
    }
}
