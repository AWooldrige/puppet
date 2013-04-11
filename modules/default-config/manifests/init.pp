class default-config {

    $enhancers = [
        'moreutils',
        'tree',
        'zip',
        'unzip',
        'strace',
        'ack-grep',
        'iotop',
        'powertop',
        'man-db',
        'curl'
    ]
    $notneeded = [
        'ack'
    ]
    package { $enhancers: ensure => installed }
    package { $notneeded: ensure => purged }

    file { '/usr/local/bin/ack':
        ensure => link,
        target => '/usr/bin/ack-grep'
    }

    file { '/etc/custom.bashrc':
        source  => 'puppet:///modules/default-config/bashrc',
        owner   => 'root',
        group   => 'root',
        mode    => '0644'
    }
    file { '/root/.bashrc':
        ensure  => link,
        target  => '/etc/custom.bashrc',
        require => File['/etc/custom.bashrc']
    }
}
