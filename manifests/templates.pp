class basenode {
    include base::packages
    include base::bashcustomisations
    include locale
    include python
    include motd
    include ntp
    include sshd
    include sudo-groups
    include vim
    include tmux
    include user-woolie
}

class basenode::desktop inherits basenode {
    include user-woolie::unmanaged-password
    include desktop::powermanagement
}

class basenode::laptop {
    include base::packages
    include dconf
    include sshd
    include sudo
    include woolie
    include woolie::ubuntuprefs
    include ubutils::sysctl
    include tmux

    # Laptop specific
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
class basenode::desktop::developmentmachine inherits basenode::desktop {
    include desktop::graphicspackages
}
