# Loopback mTLS proxy on ktcdh1, so the kiosk browser can frame Home Assistant and
# Grafana without ever holding the client certificate.
#
# Deliberately does not include the repo's `nginx` class, which is websh1-specific:
# certbot, a whole-file replacement of nginx.conf, the h.wooldrige.co.uk vhost, the
# ping and status sites, and a hardening drop-in that allow-lists websh1's ports
# and paths. Here the vendor nginx.conf is left alone and one site file is added.
class kitchen::proxy {

    include base::pki

    package { 'nginx':
        ensure => installed
    }

    # Ubuntu's default site would otherwise answer on port 80.
    file { [
            '/etc/nginx/sites-enabled/default',
            '/etc/nginx/sites-available/default'
        ]:
        ensure  => 'absent',
        require => Package['nginx'],
        notify  => Service['nginx']
    }

    file { '/etc/nginx/sites-available/kitchen-proxy':
        source  => 'puppet:///modules/kitchen/proxy/kitchen-proxy.nginx',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => [
            Package['nginx'],
            File['/etc/wooldrigepki/certificates/client.pem'],
            File['/etc/wooldrigepki/privatekeys/client.pem']
        ],
        notify  => Service['nginx']
    } ->
    file { '/etc/nginx/sites-enabled/kitchen-proxy':
        ensure => 'link',
        target => '/etc/nginx/sites-available/kitchen-proxy',
        notify => Service['nginx']
    }

    file { '/etc/systemd/system/nginx.service.d':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package['nginx']
    } ->
    file { '/etc/systemd/system/nginx.service.d/limits.conf':
        source => 'puppet:///modules/kitchen/proxy/nginx.service.limits.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify => [
            Exec['daemon-reload'],
            Service['nginx']
        ]
    }

    service { 'nginx':
        ensure  => running,
        enable  => true,
        require => [
            File['/etc/nginx/sites-enabled/kitchen-proxy'],
            File['/etc/systemd/system/nginx.service.d/limits.conf'],
            Exec['daemon-reload']
        ]
    }
}
