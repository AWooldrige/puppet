class basenode {
    # include base::packages
    # include base::bashcustomisations
    # include locale
    # include python
    # include motd
    # include ntp

    include base::packages
    include dconf
    include sshd
    include sudo
    include woolie
    include woolie::ubuntuprefs
    include ubutils::sysctl
}

class basenode::desktop inherits basenode {
    # include desktop::powermanagement
}
class basenode::laptop inherits basenode {
    # Laptop specific (usually for now)
    include dconf::lowmemmachine
}


class basenode::server inherits basenode {
    include user-woolie::managed-password
}

class basenode::desktop::raspi inherits basenode::desktop {
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
