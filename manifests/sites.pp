node default {
    user {"woolie":
        ensure  => present,
        uid     => '1500',
        gid     => 'woolie',
        groups  => 'woolie,sshallowedlogin',
        shell   => '/bin/bash',
        home    => '/home/woolie',
        managehome => true,
    }
    group { "woolie":
        ensure  => present,
        gid => '1500',
    }
    ssh_authorized_key { "woolie":
        ensure => "present",
        type => "ssh-rsa",
        key => "AAAAB3NzaC1yc2EAAAADAQABAAACAQDGoNr/PhMh2XEjsEgEGQApvcnp7AKTDyHt3A97OQTdcZ+lG5Ywx4jDpymsKU6qw9yxpElZVNIP/HLiJlfVzRlF636PIjtAyZtaoujeQGuaGp+YalqaD/YKD2LlqqHZZnsxv63IPHy7NFvpasJdHlRlaGBdLfpqvMIGgQOYlHK3M9+UDcMBK1EpftzM4x1VqGY9exs0d8bqQtIBwi7/3gVK+FymG6LM3pYnAMuCIs98T/6rwbysxV7ojogWOI5mX7uPrQhwz65AUn6PlB2LhNPhSYUAjWGePlEXG7vNMSPXyX51ZZwn4q7gAgxN9H5zi7nYQATstY6jwX7He88pvoBYxsogRQcp9TaN3gYtdEbW/HbS4v2qp2H+OuhXnMAnmejZ5Sl5FFxJIEFhbaXxBk71B9+7uX+4I3la5PZ6k7jcJMNy/RLs6xW2fBEVplMjZJQcFbmDopq03/H+v0lsXOYLdBbTF2lHadeyHNtPLeGstYWHutGsMMqSyKLF/lLgJ1tPWsj9xOAsh+iZtczmr8Wb4updr9qWw8xef5EzDyPS3RfEdYCuQ5GrwzHxWmhdK2JG998a0sv87xMGVD7D6J50jYSvgGYqbIXM6VlOfrrS/fD0Y3wBeQDnCLB7lay+USA06YTvwrvw2RxIkKSe2jseLM47nxGAjSLUj58rRyz5GQ==",
        user => "woolie",
        require => Package['openssh-server']
    }
    package { 'openssh-server':
        ensure => latest,
    }
    file { '/etc/ssh/sshd_config':
        source  => 'puppet:///modules/sshd/sshd_config',
        owner   => 'root',
        group   => 'root',
        mode    => '644',
        require => Package['openssh-server'],
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

    include puppet-auto-update
}
node "metis.woolie.co.uk" {
}
node "agw-netbook" inherits default {
}
node "dev.local" inherits default {
}
node "eros.woolie.co.uk" inherits default {
}
