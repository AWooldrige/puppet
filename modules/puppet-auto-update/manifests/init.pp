class puppet-auto-update {

    file { '/usr/bin/puppet-git-run':
        source => 'puppet:///modules/puppet-auto-update/puppet-git-run',
        owner  => 'root',
        group  => 'root',
        mode   => '0540'
    }
    file { '/usr/bin/puppet-git-update':
        source => 'puppet:///modules/puppet-auto-update/puppet-git-update',
        owner  => 'root',
        group  => 'root',
        mode   => '0540'
    }

    cron { 'puppet-git-update':
        command => '/usr/bin/chronic /usr/bin/puppet-git-update',
        user    => root,
        ensure  => present,
        hour    => 9,
        minute  => 0,
        require => [ File['/usr/bin/puppet-git-run'],
                     File['/usr/bin/puppet-git-update'] ]
    }
    cron { 'puppet-git-run':
        command => '/usr/bin/chronic /usr/bin/puppet-git-run',
        user    => root,
        ensure  => present,
        hour    => 21,
        minute  => 0,
        require => [ File['/usr/bin/puppet-git-run'],
                     File['/usr/bin/puppet-git-update'] ]
    }

    file { '/var/log/puppet-git':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/etc/logrotate.d/puppet-git':
        source => 'puppet:///modules/puppet-auto-update/etc/logrotate.d/puppet-git',
        owner  => 'root',
        group  => 'root',
        mode   => '0644'
    }
}
