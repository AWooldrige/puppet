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
        # Need to be in the video group to be able to use omxplayer on RPIs
        groups          => ['sshallowedlogin', 'passwordsudo', 'video'],
        shell           => '/bin/bash',
        home            => $homedir,
        managehome      => true,
        purge_ssh_keys  => true,
        require         => [ Group['sshallowedlogin'],
                             Group['passwordsudo'] ]
    }

    exec { "Verify manual password set for user 'woolie'":
        command     => "echo 'Password not set for \'woolie\' user. Set manually with \'passwd woolie\''; false",
        unless      => "passwd --status woolie | grep '^woolie P'",
        provider    => "shell",
        timeout     => 5,
        require     => User['woolie']
    }

    exec { "Verify temporary user 'tmpbootstrap' not present":
        command     => "echo '\'tmpbootstrap\' user still present, verify sudo access for \'woolie\' user then delete manually with \'userdel -r tmpbootstrap\''; false",
        onlyif      => "id -u tmpbootstrap",
        provider    => "shell",
        timeout     => 5
    }

    exec { "Verify temporary user 'ubuntu' not present":
        command     => "echo '\'ubuntu\' user still present, verify sudo access for \'woolie\' user then delete manually with \'userdel -r ubuntu\''; false",
        onlyif      => "id -u ubuntu",
        provider    => "shell",
        timeout     => 5
    }
}
