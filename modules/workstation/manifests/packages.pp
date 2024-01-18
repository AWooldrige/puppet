class workstation::packages {

    package { [
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
}
