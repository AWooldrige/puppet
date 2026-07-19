class raspi::spi {

    file_line { 'Enable SPI (dtparam=spi=on)':
        path => '/boot/firmware/config.txt',
        line => 'dtparam=spi=on',
    }

    file_line { 'Rewrite dtparam=spi=off to on':
        path  => '/boot/firmware/config.txt',
        line  => 'dtparam=spi=on',
        match => '^dtparam=spi=off',
    }

    package { 'python3-lgpio':
        ensure => installed,
    }

    package { ['python3-spidev', 'python3-gpiozero']:
        ensure => installed,
    }

    package { ['python3-pil', 'python3-numpy']:
        ensure => installed,
    }

    base::addusertogroup { 'Allow woolie SPI device access (/dev/spidev*)':
        ensure    => 'exists',
        username  => 'woolie',
        groupname => 'spi',
    }
}
