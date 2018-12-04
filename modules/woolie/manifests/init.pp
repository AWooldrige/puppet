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

}
