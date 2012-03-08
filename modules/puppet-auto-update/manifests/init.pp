class puppet-auto-update {
    cron { 'puppet-git-update':
        command => '/usr/bin/puppet-git-update',
        user    => root,
        ensure => present,
        minute  => [0, 10, 20, 30, 40, 50],
        require => [ File['/usr/bin/puppet-git-run'],
                     File['/usr/bin/puppet-git-update'] ]
    }
    cron { 'puppet-git-run':
        command => '/usr/bin/puppet-git-run',
        user    => root,
        ensure => present,
        minute  => [55],
        require => [ File['/usr/bin/puppet-git-run'],
                     File['/usr/bin/puppet-git-update'] ]
    }

    file { '/usr/bin/puppet-git-run':
        source => 'puppet:///modules/puppet-auto-update/puppet-git-run',
        owner => 'root',
        group => 'root',
        mode => '744'
    }
    file { '/usr/bin/puppet-git-update':
        source => 'puppet:///modules/puppet-auto-update/puppet-git-update',
        owner => 'root',
        group => 'root',
        mode => '744'
    }

    ####
    # Ensure logging is set up
    ##
    file { '/var/log/puppet-git':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '440',
    }
    file { '/etc/logrotate.d/puppet-git':
        source => 'puppet:///modules/puppet-auto-update/etc/logrotate.d/puppet-git',
        owner => 'root',
        group => 'root',
        mode => '644'
    }

    ####
    # Remove old cron jobs, scripts and log files
    ##
    cron { 'puppet-auto-update':
        command => "/usr/share/puppet-auto-update",
        user    => root,
        ensure => absent,
        minute  => [0, 10, 20, 30, 40, 50],
    }
    cron { 'puppet-run':
        command => '/usr/bin/puppet-run',
        user    => root,
        minute  => [55],
        ensure => absent,
    }

    file { "/usr/share/puppet-auto-update":
        ensure => absent
    }
    file { "/usr/share/puppet-run":
        ensure => absent
    }
    file { "/var/log/puppet/puppet-git-update":
        ensure => absent
    }
    file { "/var/log/puppet/git-distributed-auto-update":
        ensure => absent
    }
}
