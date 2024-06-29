class base::packages {

    # Essential
    package { [
        'duplicity',
        'python3-boto',  # Should be required by Duplicity in the future
        'python3-pip',
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

    if $::puppetversion and versioncmp($::puppetversion, '6.0.0') >= 0 {
        # Need to use this as it's defined in modules/apt/manifests/init.pp for
        # newer versions
        stdlib::ensure_packages(['gnupg'])
    } else {
        ensure_packages(['gnupg'])
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
        'python3-tabulate',
        'python3-tenacity',
        # 'python3.7', Not available on raspbian
        # 'python3.7-venv',
        ]:
        ensure => installed
    }
}
