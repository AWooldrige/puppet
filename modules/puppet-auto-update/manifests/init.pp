class puppet-auto-update {
    cron { puppet-auto-update:
        command => "/usr/share/puppet-auto-update",
        user    => root,
        ensure => present,
        minute  => [0, 10, 20, 30, 40, 50],
        require => File['/usr/share/puppet-auto-update']
    }

    file { "/usr/share/puppet-auto-update":
        source => "puppet:///modules/puppet-auto-update/puppet-auto-update",
        owner => 'root',
        group => 'root',
        mode => '744'
    }
}
