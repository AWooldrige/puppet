class base::packages {

    # Essential
    package { [
        'git',
        'zip',
        'unzip',
        'make',
        'vim',
        'vim-common',
        'gnupg',
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
        'rename',
        'man-db',
        'python3.7',
        'python3.7-venv']:
        ensure => installed
    }
}
