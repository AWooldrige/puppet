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

    file { "${bindir}/remove_raw_files_without_jpeg_equivalent":
        ensure => file,
        source  => 'puppet:///modules/woolie/bin/remove_raw_files_without_jpeg_equivalent',
        owner => $woolie::uname,
        group => $woolie::uname,
        mode => '0755',
        require => File[$bindir]
    }

    file { "${bindir}/resize_jpegs_for_low_quality_sharing":
        ensure => file,
        source  => 'puppet:///modules/woolie/bin/resize_jpegs_for_low_quality_sharing',
        owner => $woolie::uname,
        group => $woolie::uname,
        mode => '0755',
        require => File[$bindir]
    }
}
