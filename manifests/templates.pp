class basenode {
    include base::packages
    include gdpup
    include motd
    include ntp
    include locale
    include dconf
    include sshd
    include sudo
    include woolie
    include woolie::ubuntuprefs
    include ubutils::sysctl
}

class basenode::desktop inherits basenode {
}

class basenode::laptop inherits basenode {
}

class basenode::laptop::lowpwr inherits basenode::laptop {
    include dconf::lowmemmachine
}

class basenode::raspi inherits basenode {
    # class { 'nginx': }
    include raspi
    include raspi::boot-configuration
    include raspi::piface
    include raspi::piuser
    include raspi::dynamic-dns
    include raspi::home-automation
}
