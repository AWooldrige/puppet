class workstation::packages {

    # Editors
    package { [
        'vim-gtk3'
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
    package { 's3sup':
        ensure => installed,
        provider => 'pip3'
    }
}
