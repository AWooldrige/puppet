class prometheus3 {

    group { 'prometheus3':
        ensure => 'present',
        gid => 21002
    }

    user { 'prometheus3':
        ensure => 'present',
        comment => 'Prometheus 3 user',
        uid => 19002,
        gid => 'prometheus3',
        require => Group['prometheus3']
    }

    file { "/var/cache/packages/prometheus-3.0.0.linux-arm64.tar.gz":
        source => 'https://github.com/prometheus/prometheus/releases/download/v3.0.0/prometheus-3.0.0.linux-arm64.tar.gz',
        mode => '0644',
        require => File['/var/cache/packages']
    }
    exec { 'Install prometheus3 binaries':
        command => 'tar -xvzf /var/cache/packages/prometheus-3.0.0.linux-arm64.tar.gz -C /tmp/ && cp /tmp/prometheus-3.0.0.linux-arm64/prometheus /usr/local/bin/prometheus3 && cp /tmp/prometheus-3.0.0.linux-arm64/promtool /usr/local/bin/promtool3',
        creates => '/usr/local/bin/prometheus3',
        provider => 'shell',
        require => File["/var/cache/packages/prometheus-3.0.0.linux-arm64.tar.gz"]
    }


    file { ["/etc/prometheus3", "/var/lib/prometheus3"]:
        ensure => 'directory',
        owner => 'prometheus3',
        group => 'prometheus3',
        require => [
            User['prometheus3'],
            Group['prometheus3'],
        ]
    } ->
    file { '/etc/default/prometheus3':
        source  => 'puppet:///modules/prometheus3/prometheus3_args',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Service['prometheus3']
    } ->
    file { "/etc/nginx/h.wooldrige.co.uk.d/prometheus3.conf":
        source  => 'puppet:///modules/prometheus3/prometheus3.conf',
        owner => 'root',
        group => 'root',
        mode => '0644',
        require => File["/etc/nginx/h.wooldrige.co.uk.d"],
        notify => Service['nginx']
    } ->
    file { '/etc/prometheus3/prometheus3.yml':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Service['prometheus3'],
        content => epp(
            'prometheus3/prometheus3.yml.epp',
            {
                'home_assistant_long_lived_access_token' => $secure::home_assistant_long_lived_access_token
            }
        )
    } ->
    file { '/etc/systemd/system/prometheus3.service':
        source  => 'puppet:///modules/prometheus3/prometheus3.service',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => [
            Exec['Install prometheus3 binaries']
        ],
        notify => [
            Exec['daemon-reload'],
            Service['prometheus3']
        ]
    } ->
    service { 'prometheus3':
        ensure     => running,
        enable     => true,
        hasstatus  => true,
        hasrestart => true
    }
}
