class basenode {
    include base::packages
    include gdpup
    include motd
    include ntp
    include locale
    include sshd
    include sudo
    include woolie
    include woolie::ubuntuprefs
}

class basenode::workstation inherits basenode {
    include ubutils::sysctl
    include ubutils::epsonscanner
    include workstation::packages

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
    include ddns

    #include raspi::piface
    #include raspi::dynamic-dns
    #include raspi::home-automation
}
