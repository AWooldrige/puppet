class base::packages {

    # Essential
    package { [
        'duplicity',
        'python3-boto',  # Should be required by Duplicity in the future
        'python3-pip',
        'awscli',
        'git',
        'zip',
        'unzip',
        'make',
        'nodejs',
        'npm',
        'vim',
        'vim-common',
        'tmux',
        'curl',
        'ncal']:
        ensure => installed
    }

    # Need to use this as it's defined in modules/apt/manifests/init.pp for
    # newer versions
    ensure_packages(['gnupg'])

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
        'python3-tabulate',
        # 'python3.7', Not available on raspbian
        # 'python3.7-venv',
        ]:
        ensure => installed
    }
}
