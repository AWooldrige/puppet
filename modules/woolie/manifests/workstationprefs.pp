class woolie::workstationprefs {
    include woolie

    ###########################################################################
    # Application shortcut entries
    ###########################################################################
    file { "${woolie::homedir}/.local/share/applications/start-socks.desktop":
        source  => 'puppet:///modules/woolie/start-socks.desktop',
        owner   => $woolie::uname,
        group   => $woolie::uname,
        mode    => '0644',
        require => [ User[$woolie::uname] ]
    }

}
