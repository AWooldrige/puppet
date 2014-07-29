class base::packages {

    package { [
        'moreutils',
        'git',
        'tree',
        'zip',
        'unzip',
        'strace',
        'ack-grep',
        'iotop',
        'htop',
        'powertop',
        'man-db',
        'make',
        'g++',
        'curl']:
    ensure => installed
    }

    package { 'ack':
        ensure => purged
    }
    file { '/usr/local/bin/ack':
        ensure => link,
        target => '/usr/bin/ack-grep'
    }

}
