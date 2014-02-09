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

    file { ['/home/woolie/.vim/bundle', '/home/woolie/.vim/backup',
           '/home/woolie/.vim/tmp', '/home/woolie/.vim/undo']:
        ensure => directory,
        owner  => 'woolie',
        group  => 'woolie',
        mode   => '0755'
    }
    exec { 'install-vundle':
        command     => 'git clone https://github.com/gmarik/vundle.git /home/woolie/.vim/bundle/vundle',
        path        => [ '/usr/bin', '/bin', '/usr/local/bin' ],
        require     => [
            Package['git', 'vim'],
            File['/home/woolie/.vim/bundle']],
        logoutput   => 'true',
        user        => 'woolie',
        tries       => 3,
        creates     => '/home/woolie/.vim/bundle/vundle'
    }
}
