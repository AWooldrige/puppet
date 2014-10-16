class puppet-auto-update {

    file { ['/usr/bin/puppet-git-run',
            '/usr/bin/puppet-git-update',
            '/etc/logrotate.d/puppet-git']:
        ensure => absent
    }
    file { '/usr/bin/puppet-github-update':
        source => 'puppet:///modules/puppet-auto-update/puppet-github-update',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }

    cron { ['puppet-git-update', 'puppet-git-run']:
        ensure => absent
    }
    cron { 'puppet-github-update':
        command => '/usr/bin/chronic /usr/bin/puppet-github-update',
        user    => root,
        ensure  => present,
        hour    => 9,
        minute  => 0,
        require => File['/usr/bin/puppet-github-update']
    }

    file { '/etc/logrotate.d/puppet-github-update':
        source =>
        'puppet:///modules/puppet-auto-update/etc/logrotate.d/puppet-github-update',
        owner  => 'root',
        group  => 'root',
        mode   => '0644'
    }
}
