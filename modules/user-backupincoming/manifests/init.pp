class user-backupincoming {

    user {"backupincoming":
        ensure  => present,
        gid     => 'backupincoming',
        groups  => ['backupincoming', 'sshallowedlogin'],
        shell   => '/bin/bash',
        home    => '/home/backupincoming',
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
        key => "AAAAB3NzaC1yc2EAAAADAQABAAACAQDGoNr/PhMh2XEjsEgEGQApvcnp7AKTDyHt3A97OQTdcZ+lG5Ywx4jDpymsKU6qw9yxpElZVNIP/HLiJlfVzRlF636PIjtAyZtaoujeQGuaGp+YalqaD/YKD2LlqqHZZnsxv63IPHy7NFvpasJdHlRlaGBdLfpqvMIGgQOYlHK3M9+UDcMBK1EpftzM4x1VqGY9exs0d8bqQtIBwi7/3gVK+FymG6LM3pYnAMuCIs98T/6rwbysxV7ojogWOI5mX7uPrQhwz65AUn6PlB2LhNPhSYUAjWGePlEXG7vNMSPXyX51ZZwn4q7gAgxN9H5zi7nYQATstY6jwX7He88pvoBYxsogRQcp9TaN3gYtdEbW/HbS4v2qp2H+OuhXnMAnmejZ5Sl5FFxJIEFhbaXxBk71B9+7uX+4I3la5PZ6k7jcJMNy/RLs6xW2fBEVplMjZJQcFbmDopq03/H+v0lsXOYLdBbTF2lHadeyHNtPLeGstYWHutGsMMqSyKLF/lLgJ1tPWsj9xOAsh+iZtczmr8Wb4updr9qWw8xef5EzDyPS3RfEdYCuQ5GrwzHxWmhdK2JG998a0sv87xMGVD7D6J50jYSvgGYqbIXM6VlOfrrS/fD0Y3wBeQDnCLB7lay+USA06YTvwrvw2RxIkKSe2jseLM47nxGAjSLUj58rRyz5GQ==",
        user => "backupincoming",
        require => [ File['/home/backupincoming/.ssh'] ]
    }
}
