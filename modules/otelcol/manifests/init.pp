class otelcol {
    file { '/var/cache/packages':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    } ->
    file { "/var/cache/packages/otelcol_0.112.0_linux_arm64.deb":
        source => 'https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.112.0/otelcol_0.112.0_linux_arm64.deb',
        mode => '0644'
    } ->
    package { 'otelcol':
        ensure => installed,
        source => '/var/cache/packages/otelcol_0.112.0_linux_arm64.deb'
    }
}
