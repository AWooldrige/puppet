class raspi::epaperdisplay {

    package { ['python3-pil', 'python3-numpy']:
        ensure => installed
    }
}
