class default-config {

    $enhancers = [
        'tree',
        'unzip',
        'strace',
        'ack-grep',
        'iotop',
        'powertop',
        'man-db',
        'rdiff-backup',
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
    file { '/bkps':
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
    file { "/root/.ssh":
        ensure => directory,
        owner => 'root',
        group => 'root',
        mode => '700'
    }
    file { "/root/.ssh/id_rsa_backup8":
        owner => 'root',
        group => 'root',
        mode => '400'
    }
    file { "/etc/ssh/ssh_config":
        source => 'puppet:///modules/default-config/ssh_config',
        owner => 'root',
        group => 'root',
        mode => '400',
        require => Package['openssh-server']
    }

    include user-woolie
    include puppet-auto-update
    include apt
    include ntp
    include tmux
    include vim
    include sudo
    include sshd
    include motd
    include bash
}
