class workstation::packages {

    package { [
        'libpango1.0-0',  # Dropbox needs this
        'python3-gpg',    # Dropbox needs this
        'vim-gtk3',
        'libimage-exiftool-perl',
        'sqlitebrowser',
        'podman',
        'python3-websockets',  # Needed for vim ghost-text plugin
        'python3-pandas',
        'ledger',
        'easyeffects'
        ]:
        ensure => installed
    }

    # Static site work
    package { [
        'ruby-bundler',
        'ruby-dev',  # Required to install therubyracer
        'graphicsmagick',
        'inkscape',
        'gpick'  # Mac Colour Picker alternative
        ]:
        ensure => installed
    }
    package { [
        's3sup'
        ]:
        ensure => installed,
        provider => 'pip3',
        require => Package['python3-pip'],
        install_options => ['--break-system-packages']
    }


    ###########################################################################
    # Snap apps
    ###########################################################################
    snap::package { 'spotify':
        ensure => 'installed'
    }


    ###########################################################################
    # Flatpak apps
    ###########################################################################
    flatpak::package { 'com.logseq.Logseq':
        ensure => 'installed'
    }

    flatpak::package { 'org.cryptomator.Cryptomator':
        ensure => 'installed'
    } ->
    exec { 'allow_flatpak_cryptomator_access_to_filesystem':
        # https://community.cryptomator.org/t/cryptomator-flatpak-doesnt-find-safes/9613/2
        command => "flatpak override org.cryptomator.Cryptomator --filesystem '/mnt/bulkstorage/Dropbox/c_vaults'",
        unless => "flatpak override org.cryptomator.Cryptomator --show | grep '/mnt/bulkstorage/Dropbox/c_vaults'",
        provider => "shell"
    }

}
