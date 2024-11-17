class otelcol {
    file { "/var/cache/packages/otelcol_0.112.0_linux_arm64.deb":
        source => 'https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.112.0/otelcol_0.112.0_linux_arm64.deb',
        mode => '0644',
        require => File['/var/cache/packages']
    } ->
    package { 'otelcol':
        ensure => installed,
        source => '/var/cache/packages/otelcol_0.112.0_linux_arm64.deb'
    } ->
    base::addusertogroup { 'Allow otelcol access to Wooldrige PKI certificates':
        ensure => 'exists',
        username => 'otel',
        groupname => 'wooldrigepkicertaccess',
        require => [Group['wooldrigepkicertaccess']]
    } ->
    file { '/etc/otelcol/config.yaml':
        source  => 'puppet:///modules/otelcol/config.yaml',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Service['otelcol'],
        require => [
            File['/etc/wooldrigepki/certificates/root.pem'],
            File['/etc/wooldrigepki/certificates/server.pem'],
            File['/etc/wooldrigepki/privatekeys/server.pem']
        ]
    } ->
    service { 'otelcol':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        enable     => true
    }
}
