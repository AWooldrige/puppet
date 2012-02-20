class user-woolie {

    # Make sure home directory exists
    file { '/home/woolie':
        ensure  => directory,
        owner   => 'woolie',
        group   => 'woolie',
        mode    => '700',
    }


    # SSH configuration
    file { '/home/woolie/.ssh':
        ensure  => directory,
        owner   => 'woolie',
        group   => 'woolie',
        mode    => '700',
        require => File['/home/woolie']
    }
    file { '/home/woolie/.ssh/config':
        source  => 'puppet:///modules/user-woolie/ssh/config',
        owner   => 'woolie',
        group   => 'woolie',
        mode    => '600',
        require => File['/home/woolie/.ssh']
    }


    # git configurations
    file { '/home/woolie/.gitconfig':
        source  => 'puppet:///modules/user-woolie/gitconfig',
        owner   => 'woolie',
        group   => 'woolie',
        mode    => '600',
        require => File['/home/woolie']
    }
}
