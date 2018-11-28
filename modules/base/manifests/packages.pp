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
        'vim',
        'vim-common',
        'curl']:
        ensure => installed
    }
}
