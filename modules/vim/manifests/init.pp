class vim {
    package { 'vim':
        ensure => installed,
    }

    file { '/etc/vim':
        source  => 'puppet:///modules/vim/global',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        recurse => true,
        purge   => true,
        force   => true,
        require => Package['vim']
    }
}
