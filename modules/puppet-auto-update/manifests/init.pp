class puppet-auto-update {
    cron { 'puppet-auto-update':
        command => '/usr/bin/puppet-git-update',
        user    => root,
        ensure => present,
        minute  => [0, 10, 20, 30, 40, 50],
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
}
