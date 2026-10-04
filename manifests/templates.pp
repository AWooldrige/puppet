class basenode {
    include base::packages
    include base::utilitylibs
    include base::utildefs
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
    include podman
}

class basenode::workstation inherits basenode {
    include ubutils::sysctl
    include ubutils::epsonscanner
    include ubutils::flatpakfuse
    include workstation::packages
    include workstation::sops
    include workstation::vocalinux
    include woolie::workstationprefs
    include woolie::passwordsudo
    include influx::telegraf
    include dconf
}

class desktop inherits basenode::workstation {
}
class laptop inherits basenode::workstation {
    include dconf::lowmemmachine
}


class pi inherits basenode {
    include raspi
    include raspi::bootconfig
    include avahi
    include influx::telegraf
    include escalate
    include woolie::nopasswordsudo
    include woolie::managedpassword
}

class ktcdh1 inherits pi {
    include raspi::network
    include raspi::touchdisplay
    include raspi::pmsensor
    include raspi::cpugovernor
    include kitchen::board
    include kitchen::proxy
    include kitchen::kiosk
}
class blrsh1 inherits pi {
    include raspi::network
    include raspi::ds18b20
    include raspi::boiler
    include raspi::cpugovernor

    package { 'python3-lgpio': ensure => installed }
}


class websh1 inherits pi {
    include ddns
    include backuptool
    include raspi
    include avahi
    include raspi::network

    include nginx
    include raspi::h
    include otelcol
    include grafana
    include raspi::tiddlywiki
    include prometheus3
    include raspi::hass
    include hass
}
