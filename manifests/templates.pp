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
    include raspi::vnc
    include raspi::dynamic-dns
    include raspi::information-radiator
    include raspi::home-automation
}
class basenode::desktop::developmentmachine inherits basenode::desktop {
    include desktop::graphicspackages
}
