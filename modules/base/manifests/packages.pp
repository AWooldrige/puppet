class base::packages {

    # Essential
    package { [
        'git',
        'zip',
        'unzip',
        'make',
        'vim',
        'vim-common',
        'gpg',
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
        'linux-tools', # Has perf in
        'man-db']:
        ensure => installed
    }
}
