class ddns {
    # python3-boto3, python3-click and python3-requests come from base::packages
    package { 'python3-dnspython':
        ensure => installed
    }

    file { '/usr/local/bin/ddns':
        source  => 'puppet:///modules/ddns/ddns.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => [
            Package['python3-boto3'],
            Package['python3-click'],
            Package['python3-dnspython'],
            Package['python3-requests']
        ]
    }

    file { '/etc/systemd/system/ddns.service':
        source => 'puppet:///modules/ddns/ddns.service',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify => Exec['daemon-reload']
    }

    file { '/etc/systemd/system/ddns.timer':
        source => 'puppet:///modules/ddns/ddns.timer',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify => Exec['daemon-reload']
    }

    # /etc/aws/ddns.credentials is written by provision/
    service { 'ddns.timer':
        ensure  => running,
        enable  => true,
        require => [
            File['/usr/local/bin/ddns'],
            File['/etc/systemd/system/ddns.service'],
            File['/etc/systemd/system/ddns.timer'],
            File['/usr/local/sbin/escalate'],
            Exec['daemon-reload']
        ]
    }

    cron { [
            'Check Dynamic DNS entry at regular intervals',
            'Check Dynamic DNS entry at boot'
        ]:
        ensure => absent,
        user   => 'woolie'
    }

    file { '/home/woolie/.aws/credentials':
        ensure => absent
    }
}
