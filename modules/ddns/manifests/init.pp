class ddns {
    package { [
            # 'python3-boto3',  # Provided by base packages module
            'python3-dnspython',
            # 'python3-miniupnpc'  # Not available in Debian yet
        ]:
        ensure => installed
    } ->
    # The credentials file itself is written by provision/
    file { '/home/woolie/.aws':
        ensure  => 'directory',
        owner   => 'woolie',
        group   => 'woolie',
        mode    => '0755',
        require => User['woolie']
    } ->
    file { '/usr/local/bin/ddns':
        source  => 'puppet:///modules/ddns/ddns',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => [
            Package['python3-click'],
            Package['python3-requests']
        ]
    } ->
    cron { 'Check Dynamic DNS entry at regular intervals':
        ensure  => present,
        command => '/usr/bin/systemd-cat -t "ddns" /usr/local/bin/ddns',
        minute  => [0, 10, 20, 30, 40, 50],
        user    => 'woolie'
    } ->
    cron { 'Check Dynamic DNS entry at boot':
        ensure  => present,
        command => '/usr/bin/systemd-cat -t "ddns" /usr/local/bin/ddns',
        special => 'reboot',
        user    => 'woolie'
    }
}
