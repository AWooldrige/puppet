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
    include woolie::workstationprefs

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
    include raspi::noscreenblanking
}
class livingroomtvpi inherits pi {
    include ddns
}
class kitchentvpi inherits pi {
    include raspi::inforad
}
