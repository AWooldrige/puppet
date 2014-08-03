class desktop::graphicspackages {

    package { ['inkscape', 'gimp']:
        ensure => installed
    }

}
