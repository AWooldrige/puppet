class default-config {

    $enhancers = [
        'tree',
        'strace',
        'ack-grep',
        'iotop',
        'man-db',
        'pwgen',
        'curl'
    ]
    $notneeded = [
        'ack'
    ]
    package { $enhancers: ensure => installed }
    package { $notneeded: ensure => purged }

    # Alias ack to ack-grep
    exec { "/bin/ln -sf /usr/bin/ack-grep /usr/local/bin/ack":
        unless => "/bin/sh -c '[ -L /usr/local/bin/ack ]'",
        require => Package['ack-grep']
    }

    file { '/root/extlookup':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '400',
    }
    file { '/root/extlookup/common.csv':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '400',
    }
    file { "/root/getpassword":
        source => 'puppet:///modules/default-config/getpassword',
        owner => 'root',
        group => 'root',
        mode => '700',
        require => [ Package['pwgen'],
                     File['/root/extlookup'] ]
    }

    include user-woolie
    include puppet-auto-update
    include ntp
    include tmux
    include vim
    include sudo
    include sshd
    include bash
}
