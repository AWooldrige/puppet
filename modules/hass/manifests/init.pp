class hass {

    group { 'homeassistant':
        ensure => 'present',
        gid => 21004
    }

    user { 'homeassistant':
        ensure => 'present',
        comment => 'Home assistant user',
        uid => 19004,
        gid => 'homeassistant',
        groups => ['bluetooth'],
        require => [Group['homeassistant'], Package['bluez']]
    }

    file { '/var/lib/homeassistant':
        ensure => 'directory',
        owner => 'homeassistant',
        group => 'homeassistant',
        require => [
            User['homeassistant'],
            Group['homeassistant'],
        ]
    }

    file { '/etc/udev/rules.d/99-sonoff-zigbee.rules':
        source  => 'puppet:///modules/hass/99-sonoff-zigbee.rules',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify => [
            Exec['udev-reload'],
            Service['home-assistant']
        ]
    }

    file { ['/etc/containers', '/etc/containers/systemd']:
        ensure => 'directory',
        owner => 'root',
        group => 'root'
    }

    file { '/etc/containers/systemd/home-assistant.container':
        source  => 'puppet:///modules/hass/home-assistant.container',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => [
            File['/etc/containers/systemd']
        ],
        notify => [
            Exec['daemon-reload'],
            Exec['verify-quadlet-configs'],
            Service['home-assistant']
        ]
    }
    exec { 'verify-quadlet-configs':
        command => '/usr/lib/systemd/system-generators/podman-system-generator --dryrun',
        provider => 'shell',
        refreshonly => true,
        require => Package['podman']
    }

    # Needed by HASS bluetooth integration.
    package { 'bluez':
        ensure => installed
    } ->
    service { 'bluetooth':
        ensure => running,
        enable => true
    }

    file { '/etc/dbus-1/system.d/home-assistant-bluetooth.conf':
        source  => 'puppet:///modules/hass/home-assistant-bluetooth-dbus.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Service['bluetooth'],
        notify  => [
            Exec['reload-dbus-config'],
            Service['home-assistant']
        ]
    }

    exec { 'reload-dbus-config':
        command     => '/usr/bin/busctl call org.freedesktop.DBus / org.freedesktop.DBus ReloadConfig',
        refreshonly => true
    }

    package { 'dbus-broker':
        ensure => installed
    } ->
    service { 'dbus-broker':
        ensure => running,
        enable => true
    }

    service { 'home-assistant':
        ensure  => running,
        enable  => true,
        require => [
            Package['bluez'],
            Service['bluetooth'],
            Service['dbus-broker'],
            File['/etc/dbus-1/system.d/home-assistant-bluetooth.conf'],
            Exec['reload-dbus-config'],
            File['/etc/udev/rules.d/99-sonoff-zigbee.rules'],
            Exec['verify-quadlet-configs'],
            Exec['daemon-reload']
        ]
    }

    file { '/var/lib/homeassistant/configuration.yaml':
        source  => 'puppet:///modules/hass/configuration.yaml',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => [
            File['/var/lib/homeassistant'],
            File['/var/lib/homeassistant/packages']
        ],
        notify => [
            Service['home-assistant'],
            Exec['verify-home-assistant-configuration-yaml']
        ]
    }
    exec { 'verify-home-assistant-configuration-yaml':
        command => 'podman exec homeassistant python -m homeassistant --script check_config --config /config',
        provider => 'shell',
        refreshonly => true,
        require => Service['home-assistant']
    }

    file { '/var/lib/homeassistant/packages':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => File['/var/lib/homeassistant'],
    }

    file { [
            '/etc/nginx/sites-enabled/epaper-board',
            '/etc/nginx/sites-available/epaper-board'
        ]:
        ensure => 'absent',
        notify => Exec['reload-nginx']
    }
    file { '/var/lib/homeassistant/packages/epaper.yaml':
        ensure  => 'absent',
        require => File['/var/lib/homeassistant/packages'],
        notify  => [
            Service['home-assistant'],
            Exec['verify-home-assistant-configuration-yaml']
        ]
    }

    file { '/usr/local/sbin/backup-hass':
        source => 'puppet:///modules/hass/backup-hass',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }
    cron { 'Backup hass daliy':
        ensure  => present,
        command => '/usr/bin/systemd-cat -t "backup-hass" /usr/local/sbin/backup-hass',
        hour => [7],
        minute => 5,
        require => [
            File['/usr/local/sbin/backup-hass'],
            File['/var/lib/homeassistant']
        ]
    }
}
