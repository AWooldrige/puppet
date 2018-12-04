class base::packages {

    # Essential
    package { [
        'git',
        'zip',
        'unzip',
        'make',
        'vim',
        'vim-common',
        'tmux',
        'curl']:
        ensure => installed
    }

    # Nice to have
    package { [
        'tree',
        'strace',
        'ack',
        'iotop',
        'htop',
        'powertop',
        'man-db']:
        ensure => installed
    }
}
