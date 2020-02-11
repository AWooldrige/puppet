class base::packages {

    # Essential
    package { [
        'duplicity',
        'python-boto',  # Sadly still required by Duplicity
        'python3-boto',  # Should be required by Duplicity in the future
        'awscli',
        'git',
        'zip',
        'unzip',
        'make',
        'nodejs',
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
