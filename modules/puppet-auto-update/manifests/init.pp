class puppet-auto-update {
    cron { 'puppet-git-update':
        command => '/usr/bin/puppet-git-update',
        user    => root,
        ensure => present,
        minute  => [0, 10, 20, 30, 40, 50],
        require => [ File['/usr/bin/puppet-run'],
                     File['/usr/bin/puppet-git-update'] ]
    }
    cron { 'puppet-run':
        command => '/usr/bin/puppet-run',
        user    => root,
        ensure => present,
        minute  => [55],
        require => [ File['/usr/bin/puppet-run'],
                     File['/usr/bin/puppet-git-update'] ]
    }

    file { '/usr/bin/puppet-run':
        source => 'puppet:///modules/puppet-auto-update/puppet-run',
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


    ####t
    # Remove old cron jobs and file
    ##
    cron { 'puppet-auto-update':
        command => "/usr/share/puppet-auto-update",
        user    => root,
        ensure => absent,
        minute  => [0, 10, 20, 30, 40, 50],
    }

    file { "/usr/share/puppet-auto-update":
        ensure => absent
    }
}
