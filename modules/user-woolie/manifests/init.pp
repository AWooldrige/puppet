class user-woolie {
    #Note that although a password hash is here, the user has passwordless sudo
    #access, and can only use a private key to SSH in.
    user { 'woolie':
        ensure     => present,
        gid        => 'woolie',
        groups     => ['woolie', 'sshallowedlogin', 'nopasswordsudo'],
        shell      => '/bin/bash',
        home       => '/home/woolie',
        managehome => true,
        password   => '$6$wFGJsfWVA$FHdGuY2QpV0V78tKA17wjJtRla4WMvk7Ev9YVAhds6pU8ugiUFMuo1pTWP.Jc1C.8yuf0jVdKZmTC2TXDJu5M1',
        require    => [ Group['woolie'],
                        Group['sshallowedlogin'],
                        Group['nopasswordsudo'] ]
    }
    group { ['woolie']:
        ensure  => present,
    }

    # SSH Config
    ssh_authorized_key { 'woolie':
        ensure  => present,
        type    => 'ssh-rsa',
        key     => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQDGoNr/PhMh2XEjsEgEGQApvcnp7AKTDyHt3A97OQTdcZ+lG5Ywx4jDpymsKU6qw9yxpElZVNIP/HLiJlfVzRlF636PIjtAyZtaoujeQGuaGp+YalqaD/YKD2LlqqHZZnsxv63IPHy7NFvpasJdHlRlaGBdLfpqvMIGgQOYlHK3M9+UDcMBK1EpftzM4x1VqGY9exs0d8bqQtIBwi7/3gVK+FymG6LM3pYnAMuCIs98T/6rwbysxV7ojogWOI5mX7uPrQhwz65AUn6PlB2LhNPhSYUAjWGePlEXG7vNMSPXyX51ZZwn4q7gAgxN9H5zi7nYQATstY6jwX7He88pvoBYxsogRQcp9TaN3gYtdEbW/HbS4v2qp2H+OuhXnMAnmejZ5Sl5FFxJIEFhbaXxBk71B9+7uX+4I3la5PZ6k7jcJMNy/RLs6xW2fBEVplMjZJQcFbmDopq03/H+v0lsXOYLdBbTF2lHadeyHNtPLeGstYWHutGsMMqSyKLF/lLgJ1tPWsj9xOAsh+iZtczmr8Wb4updr9qWw8xef5EzDyPS3RfEdYCuQ5GrwzHxWmhdK2JG998a0sv87xMGVD7D6J50jYSvgGYqbIXM6VlOfrrS/fD0Y3wBeQDnCLB7lay+USA06YTvwrvw2RxIkKSe2jseLM47nxGAjSLUj58rRyz5GQ==',
        user    => 'woolie'
    }
    file { '/home/woolie/.ssh/config':
        source  => 'puppet:///modules/user-woolie/ssh/config',
        owner   => 'woolie',
        group   => 'woolie',
        mode    => '0644',
        require => Ssh_authorized_key['woolie']
    }

    # git configurations
    file { '/home/woolie/.gitconfig':
        source  => 'puppet:///modules/user-woolie/gitconfig',
        owner   => 'woolie',
        group   => 'woolie',
        mode    => '0600',
        require => User['woolie']
    }

    file { '/home/woolie/.bashrc':
        ensure  => link,
        target  => '/etc/custom.bashrc',
        require => User['woolie']
    }

    file { '/home/woolie/workspace/':
        ensure => directory,
        owner  => 'woolie',
        group  => 'woolie',
        mode   => '0755'
    }

    file { '/usr/bin/populate-workspace':
        source => 'puppet:///modules/user-woolie/populate-workspace',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }
}
