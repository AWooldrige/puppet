class workstation::packages {

    package { [
        'vim-gtk3',
        'exiftool',
        'sqlitebrowser',
        'podman',
        'ledger',
        'pulseeffects'
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
        'pysocks',
        's3sup',
        'websockets',  # Required by vim ghost-text plugin
        'pandas'
        ]:
        ensure => installed,
        provider => 'pip3',
        require => Package['python3-pip']
    }
}
