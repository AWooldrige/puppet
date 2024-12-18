class ddns {
    package { [
            'python3-boto3',
            'python3-dnspython',
            # 'python3-miniupnpc'  # Not available in Debian yet
        ]:
        ensure => installed
    } ->
    file { '/home/woolie/.aws':
        ensure  => 'directory',
        owner   => 'woolie',
        group   => 'woolie',
        mode    => '0755',
        require => User['woolie']
    } ->
    exec { 'Create AWS credentials file':
        command     => "/bin/echo -e '# For /usr/bin/ddns\n[ddns]\naws_access_key_id=\naws_secret_access_key=' >> /home/woolie/.aws/credentials",
        unless      => "/bin/grep -q '[ddns]' /home/woolie/.aws/credentials",
        provider    => "shell",
        user        => 'woolie'
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
