class basenode {
    include base::packages

    include motd
    include ntp
    include locale
    include sshd
    include sudo
    include woolie
    include woolie::ubuntuprefs
}

class basenode::workstation {
    include ubutils::sysctl
    include ubutils::epsonscanner

    # dconf not used by lightdm
    include dconf
}

class desktop inherits basenode::workstation {
}
class laptop inherits basenode::workstation {
    # Laptop specific (usually for now)
    include dconf::lowmemmachine
}


class pi inherits basenode {
    include raspi
    include raspi::autologin

    #include raspi::piface
    #include raspi::dynamic-dns
    #include raspi::home-automation
}
