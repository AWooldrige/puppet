class user-woolie {
    group { ['woolie']:
        ensure  => present,
    }

    ssh_authorized_key { 'woolie':
        ensure  => present,
        type    => 'ssh-rsa',
        key     => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQDgBdC9rm9eDIOPKcGNRjz5j/M7wVM+TQjN5oAY/ExyZ1WM7yBkdvepqlDScdUgkpY7+HQLtJ2PDqOk0fRh0JZ7fDKT5glhhtwAokU4CbRpRZFLrL/Vdyumyql2cTvYXhMqkymhVnz9Za4K48EbbTQSU/tjy2Mv3rm1RgDaBXhuVPbZ/k53SxL7zxlxowEu6kClGfCnV2uLhyjAU93gxhPmPd11j02NAtoTAIiQEYm79cWKYcsZZlLXc17z89kpNrRJF+Edu/cekO2/gCF2LWXQzuG0dfs/9fFr4dhMEYavYcK1uvxJGkb0p9G7VZ9UVj3UpKSMK87Hz8on588wC9CLBcs4/029yXZDmywiyDuyomDuPFSnw1cH7vEX9s3rISpx6+PD/+veDsCIAGn2ACyS9M7yBCwDHrdWhdcFcV4JM0Act1bRs3MUQCBzxw8Klh5nSfLBuof4olmSQe3N2eDpHcTLh/CE5B356tSsM5/lGSb/axV7saSefKXild87COaFwSdJDlKO9Iylma82RVY8bMS3SphSrD8MLFURRsnVFxR7JwpV2zMiAx6h/RUZpCYiu4YAYQWWvdLF2wQHjwx4Zf377volNwhWOua7NoBtcX32EBIVqhH44RahXgMzEEtbPu086s3mcpTgTg1i4Hnw9CbS11xNH9UCazL2aOX01Q==',
        user    => 'woolie',
        require => User['woolie']
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
        mode   => '0755',
        require => User['woolie']
    }

    file { '/usr/bin/populate-workspace':
        source => 'puppet:///modules/user-woolie/populate-workspace',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }
}

class user-woolie::managed-password {
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
}

class user-woolie::unmanaged-password {
    #TODO: This doesn't seem to be setting the groups right?
    user { 'woolie':
        ensure     => present,
        gid        => 'woolie',
        groups     => ['woolie', 'sshallowedlogin', 'passwordsudo'],
        shell      => '/bin/bash',
        home       => '/home/woolie',
        managehome => true,
        require    => [ Group['woolie'],
                        Group['sshallowedlogin'],
                        Group['passwordsudo'] ]
    }
}
