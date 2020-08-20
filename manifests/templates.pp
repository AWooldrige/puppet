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
    include secure
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
    include avahi
    include influx::telegraf
}
class webpi inherits pi {
    include ddns
    include influx::influxdb
    include influx::grafana
    include pihole
    include nginx
    include raspi::photos
    include raspi::tiddlywiki
    include raspi::cg
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
}
class frigdepi inherits pi {
    include raspi::wifi
    include raspi::spi
}
