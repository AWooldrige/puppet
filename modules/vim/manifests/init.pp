class vim {
    package { 'vim':
        ensure => latest,
    }
    file { '/etc/vim/vimrc.local':
        source  => 'puppet:///modules/vim/vimrc.local',
        owner   => 'root',
        group   => 'root',
        mode   => '644',
        require => Package['vim'],
    }


    ####
    ## COLOURS
    ####
    file { '/etc/vim/colors':
        ensure  => directory,
        owner   => 'woolie',
        group   => 'woolie',
        mode    => '400'
    }
    file { '/etc/vim/colors/wombat.vim':
        source  => 'puppet:///modules/vim/colors/wombat.vim',
        owner   => 'root',
        group   => 'root',
        mode   => '644',
        require => File['/etc/vim/colors']
    }
    file { '/etc/vim/colors/solarized.vim':
        source  => 'puppet:///modules/vim/colors/solarized.vim',
        owner   => 'root',
        group   => 'root',
        mode   => '644',
        require => File['/etc/vim/colors']
    }


    ####
    ## DOCS
    ####
    file { '/etc/vim/doc':
        ensure  => directory,
        owner   => 'woolie',
        group   => 'woolie',
        mode    => '400'
    }
    file { '/etc/vim/doc/NERD_tree.txt':
        source  => 'puppet:///modules/vim/doc/NERD_tree.txt',
        owner   => 'root',
        group   => 'root',
        mode   => '644',
        require => File['/etc/vim/doc']
    }
    file { '/etc/vim/doc/tags.vim':
        source  => 'puppet:///modules/vim/doc/tags.vim',
        owner   => 'root',
        group   => 'root',
        mode   => '644',
        require => File['/etc/vim/doc']
    }


    ####
    ## PLUGINS
    ####
    file { '/etc/vim/plugin':
        ensure  => directory,
        owner   => 'woolie',
        group   => 'woolie',
        mode    => '400'
    }
    file { '/etc/vim/plugin/NERD_tree.vim':
        source  => 'puppet:///modules/vim/plugin/NERD_tree.vim',
        owner   => 'root',
        group   => 'root',
        mode   => '644',
        require => File['/etc/vim/plugin']
    }
    file { '/etc/vim/plugin/taglist.vim':
        source  => 'puppet:///modules/vim/plugin/taglist.vim',
        owner   => 'root',
        group   => 'root',
        mode   => '644',
        require => File['/etc/vim/plugin']
    }
    file { '/etc/vim/plugin/tabname.vim':
        source  => 'puppet:///modules/vim/plugin/tabname.vim',
        owner   => 'root',
        group   => 'root',
        mode   => '644',
        require => File['/etc/vim/plugin']
    }
}
