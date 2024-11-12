class workstation::packages {

    package { [
        # 'libpango1.0-0',  # Dropbox needs this
        'python3-gpg',    # Dropbox needs this
        'vim-gtk3',
        'libimage-exiftool-perl',
        'sqlitebrowser',
        'podman',
        'python3-websockets',  # Needed for vim ghost-text plugin
        'python3-pandas',
        'python3-fuzzywuzzy',  # Accounts
        'python3-structlog',
        # https://github.com/rbenv/ruby-build/discussions/2012#discussioncomment-4619519
        'libyaml-dev',  # Needed for installing nanoc gem (one of the deps)
        'ledger',
        'gnome-boxes'
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
        ensure => 'absent'
    }

    package { 'easyeffects':
        ensure => absent
    }
    flatpak::package { 'com.github.wwmm.easyeffects':
        ensure => 'installed'
    }

    flatpak::package { 'org.cryptomator.Cryptomator':
        ensure => 'installed'
    } ->
    exec { 'allow_flatpak_cryptomator_access_to_filesystem':
        # https://community.cryptomator.org/t/cryptomator-flatpak-doesnt-find-safes/9613/2
        command => "flatpak override org.cryptomator.Cryptomator --filesystem '/media/woolie/bulkstorage/Dropbox/c_vaults'",
        unless => "flatpak override org.cryptomator.Cryptomator --show | grep '/media/woolie/bulkstorage/Dropbox/c_vaults'",
        provider => "shell"
    }

}
