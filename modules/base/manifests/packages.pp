class base::packages {

    # Essential
    package { [
        'duplicity',
        'python3-boto3', # Needed by duplicity for S3 backups
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
        'pv',
        'iotop',
        'htop',
        'powertop',
        'rename',
        'man-db',
        'inotify-tools',  # Includes inotifywait
        'python3-tabulate',
        'python3-tenacity',
        'python3-click',
        'python3-requests',
        ]:
        ensure => installed
    }

    # Every apt invocation on the box waits for the lock instead of failing on it,
    # Puppet's package provider included. unattended-upgrades can hold it for half
    # an hour on a newly installed machine.
    file { '/etc/apt/apt.conf.d/99-lock-timeout':
        ensure  => 'file',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => @("EOT")
            //######################################################################
            //##   This file is controlled by Puppet - changes will be overwritten ##
            //######################################################################
            DPkg::Lock::Timeout "1800";
            | EOT
    }
    File['/etc/apt/apt.conf.d/99-lock-timeout'] -> Package<| |>

    # Place to store manually downloaded ones
    file { '/var/cache/packages':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }
}
