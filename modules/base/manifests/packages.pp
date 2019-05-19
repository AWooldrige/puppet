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
        'inotify-tools',  # Includes inotifywait
        # 'python3.7', Not available on raspbian
        # 'python3.7-venv',
        ]:
        ensure => installed
    }
}
