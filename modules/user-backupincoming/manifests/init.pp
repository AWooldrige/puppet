class user-backupincoming {

    user {"backupincoming":
        ensure  => present,
        gid     => 'backupincoming',
        groups  => ['backupincoming', 'sshallowedlogin'],
        shell   => '/bin/bash',
        home    => '/home/backupincoming',
        password => generate('/root/getpassword', 'user_backupincoming'),
        managehome => true
    }
    group { "backupincoming":
        ensure  => present,
    }
    file { '/home/backupincoming':
        ensure  => directory,
        owner   => 'backupincoming',
        group   => 'backupincoming',
        mode    => '700',
        require => User['backupincoming']
    }


    # SSH configuration
    file { '/home/backupincoming/.ssh':
        ensure  => directory,
        owner   => 'backupincoming',
        group   => 'backupincoming',
        mode    => '700',
        require => File['/home/backupincoming']
    }
    ssh_authorized_key { "backupincoming":
        ensure => "present",
        type => "ssh-rsa",
        key => "AAAAB3NzaC1yc2EAAAADAQABAAABAQDFBRA1l8X79XY+YAdwerRNYiqk0Xt5S7B4U5tB1LUksiuxAAntHdFLzPfoHFeKK5b274PGdYnKRmFluVnvIjAZhxjfpbGQViFV0yv65ZTRXVBUvwPKFxYlZHFz6qOChGs114voxUwCXKNJv3u3Re0Ofl6h8ei1ZDq8K9x8J6eapSMrpSoqy7E1xpQd8d3LqXgep5n5rug49378fx+ZLG2RIovRcznvW0N2kquQP7pkK1gsgfynIfsHK7n9a8Oc4gvDBCA/PRXfFt44KWpdmJZhv4all5G+SPLB4dpcWQieNO1bCUwTBFaV0GeTOAfPbkcnyhbfkB3agYqM3AnVWwIp",
        user => "backupincoming",
        require => [ File['/home/backupincoming/.ssh'] ]
    }
}
