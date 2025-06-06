class basenode {
    include base::packages
    include base::utilitylibs
    include base::pki
    include toggles
    include gdpup
    include motd
    include ntp
    include locale
    include sshd
    include sudo
    include woolie
    include woolie::ubuntuprefs
    include secure
}

class basenode::workstation inherits basenode {
    include ubutils::sysctl
    include ubutils::epsonscanner
    include workstation::packages
    include woolie::workstationprefs
    include influx::telegraf

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
    include raspi::bootconfig
    include avahi
    include influx::telegraf
    include escalate
}
class webpi inherits pi {
    include ddns::remove

    # Raspbian version not up-to-date enough yet.
    # python3-lgpio only available on Ubuntu Server.
    # ds18b20_manager autodetects, with fallback to RPi.GPIO
    package { 'python3-lgpio': ensure => installed }
    include raspi::ds18b20
}
class kitchentvpi inherits pi {
    include raspi::autologin
    include raspi::noscreenblanking
    include raspi::inforad
}
class epaperpi inherits pi {
    include raspi::wifi
    include raspi::spi
    include raspi::epaperdisplay
    include raspi::epim
    include raspi::pmsensor
}
class boilerpi inherits pi {
    include raspi::autowifirestart
    include raspi::ds18b20
    include raspi::boiler
}


class websh1 inherits pi {
    include ddns
    include backuptool
    include raspi
    include avahi
    include docker::docker

    include nginx
    include raspi::h
    include otelcol
    include grafana
    include raspi::tiddlywiki
    include prometheus3
}
