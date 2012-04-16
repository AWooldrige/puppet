class gvim {

    package { 'exuberant-ctags':
        ensure  => installed
    }
    package { 'vim-gnome':
        ensure  => installed,
        require => Package['exuberant-ctags']
    }
    file { '/etc/vim/gvimrc.local':
        source  => 'puppet:///modules/gvim/gvimrc.local',
        owner   => 'root',
        group   => 'root',
        mode    => '644',
        require => Package['vim-gnome'],
    }
}
