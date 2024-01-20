class flatpak {

    package { [ 'flatpak' ]:
        ensure => installed
    }

    exec { 'flathub_repo':
        command => "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo",
        unless => "flatpak remotes | egrep '^flathub'",
        provider => "shell",
        require => [ Package['flatpak'] ]
    }

}
