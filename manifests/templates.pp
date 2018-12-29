class basenode {
    include base::packages

    include motd
    include ntp
    include locale
    include dconf
    include sshd
    include sudo
    include woolie
    include woolie::ubuntuprefs
}

class basenode::workstation {
    include ubutils::sysctl
    include ubutils::epsonscanner
}

class desktop inherits basenode::workstation {
}
class laptop inherits basenode::workstation {
    # Laptop specific (usually for now)
    include dconf::lowmemmachine
}


class basenode::server inherits basenode {
    include user-woolie::managed-password
}

class raspi inherits basenode::desktop {
    class { 'nginx': }
    include puppet-auto-update
    include raspi
    include raspi::boot-configuration
    include raspi::piface
    include raspi::piuser
    include raspi::dynamic-dns
    include raspi::home-automation

    # Thing that shouldn't be installed
    include raspi::vnc::remove
    include raspi::information-radiator::remove

}
