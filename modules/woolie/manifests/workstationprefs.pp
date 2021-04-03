class woolie::workstationprefs {
    include woolie

    $localdir = "${woolie::homedir}/.local"
    file { "$localdir":
        ensure => directory,
        owner => $woolie::uname,
        group => $woolie::uname,
        require => User[$woolie::uname]
    }

    ###########################################################################
    # Application shortcut entries
    ###########################################################################
    $sharedir = "${woolie::homedir}/.local/share"
    file { "$sharedir":
        ensure => directory,
        owner => $woolie::uname,
        group => $woolie::uname,
        require => [
            User[$woolie::uname],
            File[$localdir]
        ]
    }
    file { "${sharedir}/applications/start-socks.desktop":
        source  => 'puppet:///modules/woolie/start-socks.desktop',
        owner   => $woolie::uname,
        group   => $woolie::uname,
        mode    => '0644',
        require => File[$sharedir]
    }


    ###########################################################################
    # Application shortcut entries
    ###########################################################################

    # Ubuntu's default ~/.profile adds ~/bin to the PATH, but ~/.local/bin is
    #the systemd convention
    $bindir = "${woolie::homedir}/.local/bin"

    file { "$bindir":
        ensure => directory,
        owner => $woolie::uname,
        group => $woolie::uname,
        require => [
            User[$woolie::uname],
            File[$localdir]
        ]
    }

    # TODO: Puppet's checksum_value is only used for change detection.  It does
    # NOT validate the checksum of the downloaded file, so this should be done
    # using an exec.
    file { "${bindir}/google-font-downloader":
        ensure => file,
        source => 'https://github.com/neverpanic/google-font-download/raw/b0844341d1508ec1f8382f335c10354d1560d8ca/google-font-download',
        checksum => md5,
        checksum_value => 'ece5cda61be427fbc26426ee54f5b1c5',
        owner => $woolie::uname,
        group => $woolie::uname,
        mode => '0755',
        require => File[$bindir]
    }

    file { "${bindir}/start_socks":
        ensure => file,
        source  => 'puppet:///modules/woolie/bin/start_socks',
        owner => $woolie::uname,
        group => $woolie::uname,
        mode => '0755',
        require => File[$bindir]
    }

    file { "${bindir}/ssh_key_gen":
        ensure => file,
        source  => 'puppet:///modules/woolie/bin/ssh_key_gen',
        owner => $woolie::uname,
        group => $woolie::uname,
        mode => '0755',
        require => File[$bindir]
    }

    file { "${bindir}/photos_dir_gen":
        ensure => file,
        source  => 'puppet:///modules/woolie/bin/photos_dir_gen',
        owner => $woolie::uname,
        group => $woolie::uname,
        mode => '0755',
        require => File[$bindir]
    }
}
