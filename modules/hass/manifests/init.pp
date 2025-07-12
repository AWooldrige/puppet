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
        require => Group['homeassistant']
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
        refreshonly => true
    }

    # Needed by HASS bluetooth integration
    package { 'bluez':
        ensure => installed
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
            Service['dbus-broker'],
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
            File['/var/lib/homeassistant']
        ],
        notify => [
            Service['home-assistant'],
            Exec['verify-home-assistant-configuration-yaml']
        ]
    }
    # There's an obvious initial install race condition here that I need to
    # sort out at some point
    exec { 'verify-home-assistant-configuration-yaml':
        command => 'podman exec homeassistant python -m homeassistant --script check_config --config /config',
        provider => 'shell',
        refreshonly => true
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
        # Home assistant backups default to running between 04:45 and 05:45
        hour => [7],
        minute => 5,
        require => [
            File['/usr/local/sbin/backup-hass'],
            File['/var/lib/homeassistant']
        ]
    }
}
