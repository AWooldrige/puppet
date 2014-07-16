class vim {

    package { ['vim', 'vim-common', 'vim-gtk']:
        ensure => installed
    }

    file { '/etc/vim/vimrc.local':
        source  => 'puppet:///modules/vim/vimrc.local',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['vim-common']
    }

    file { '/etc/vim/bundle':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package['vim-common']
    }

    # Sometimes the git command will fail, but will still create the vundle
    # directory. This is why the directory is removed as part of the command,
    # and the README.md file is used to determine a successful clone.
    exec { 'install-vundle':
        command     => 'rm -rf /etc/vim/bundle/vundle && git clone https://github.com/gmarik/vundle.git /etc/vim/bundle/vundle',
        path        => ['/usr/bin', '/bin', '/usr/local/bin'],
        require     => [Package['git', 'vim-gtk'], File['/etc/vim/bundle']],
        logoutput   => 'true',
        user        => 'root',
        tries       => 3,
        creates     => '/etc/vim/bundle/vundle/README.md'
    }
}
