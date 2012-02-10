node default {
    user {"woolie":
        ensure  => present,
        uid     => '1500',
        gid     => 'woolie',
        groups  => 'woolie',
        shell   => '/bin/bash',
        home    => '/home/woolie',
        managehome => true,
    }
    group { "woolie":
        ensure  => present,
        gid => '1500',
    }


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


    package { 'tmux':
        ensure => latest,
    }
    file { '/etc/tmux.conf':
        source  => 'puppet:///modules/tmux/tmux.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '644',
        require => package['tmux'],
    }

    $enhancers = [  "tree",
                    "strace",
                    "sudo" ]
    package { $enhancers: ensure => "installed" }
}
node "metis.woolie.co.uk" {
}
node "agw-netbook" inherits default {
}
node "dev.local" inherits default {
}
node "eros.woolie.co.uk" inherits default {
}
