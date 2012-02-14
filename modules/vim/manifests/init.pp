class vim {
    package { 'vim':
        ensure => latest,
    }
    file { '/etc/vim/vimrc.local':
        source  => 'puppet:///modules/vim/vimrc.local',
        owner   => 'root',
        group   => 'root',
        mode    => '644',
        require => package['vim'],
    }
}
