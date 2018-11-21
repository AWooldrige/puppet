class base::packages {

    package { [
        'git',
        'tree',
        'zip',
        'unzip',
        'strace',
        'ack',
        'iotop',
        'htop',
        'powertop',
        'man-db',
        'make',
        'curl']:
        ensure => installed
    }

    file { '/usr/local/bin/ack':
        ensure => link,
        target => '/usr/bin/ack-grep'
    }

}
