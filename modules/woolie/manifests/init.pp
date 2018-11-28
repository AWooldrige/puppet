class woolie {
    $uname = 'woolie'
    $homedir = "/home/$uname"

    group { $uname:
        ensure  => present,
        gid     => 20001  # Best to sync GIDs across machines
    }

    user { $uname:
        ensure          => present,
        expiry          => absent,
        uid             => 18001,  # Best to sync UIDs across machines
        gid             => $uname,
        groups          => ['sshallowedlogin', 'passwordsudo'],
        shell           => '/bin/bash',
        home            => $homedir,
        managehome      => true,
        purge_ssh_keys  => true,
        require         => [ Group['sshallowedlogin'],
                             Group['passwordsudo'] ]
    }

    ssh_authorized_key { $uname:
        ensure  => present,
        user    => $uname,
        type    => 'ssh-rsa',
        key     => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQDgBdC9rm9eDIOPKcGNRjz5j/M7wVM+TQjN5oAY/ExyZ1WM7yBkdvepqlDScdUgkpY7+HQLtJ2PDqOk0fRh0JZ7fDKT5glhhtwAokU4CbRpRZFLrL/Vdyumyql2cTvYXhMqkymhVnz9Za4K48EbbTQSU/tjy2Mv3rm1RgDaBXhuVPbZ/k53SxL7zxlxowEu6kClGfCnV2uLhyjAU93gxhPmPd11j02NAtoTAIiQEYm79cWKYcsZZlLXc17z89kpNrRJF+Edu/cekO2/gCF2LWXQzuG0dfs/9fFr4dhMEYavYcK1uvxJGkb0p9G7VZ9UVj3UpKSMK87Hz8on588wC9CLBcs4/029yXZDmywiyDuyomDuPFSnw1cH7vEX9s3rISpx6+PD/+veDsCIAGn2ACyS9M7yBCwDHrdWhdcFcV4JM0Act1bRs3MUQCBzxw8Klh5nSfLBuof4olmSQe3N2eDpHcTLh/CE5B356tSsM5/lGSb/axV7saSefKXild87COaFwSdJDlKO9Iylma82RVY8bMS3SphSrD8MLFURRsnVFxR7JwpV2zMiAx6h/RUZpCYiu4YAYQWWvdLF2wQHjwx4Zf377volNwhWOua7NoBtcX32EBIVqhH44RahXgMzEEtbPu086s3mcpTgTg1i4Hnw9CbS11xNH9UCazL2aOX01Q==',
        require => User[$uname]
    }
}
