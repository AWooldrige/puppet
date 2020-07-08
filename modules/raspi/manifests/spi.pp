class raspi::spi {

    # This does require a reboot
    file_line { 'Enable SPI in Raspberry PI BIOS equiv':
        path => '/boot/firmware/usercfg.txt',
        line => 'dtparam=spi=on',
    }

    file { '/usr/bin/install-bcm2835':
        source => 'puppet:///modules/raspi/spi/install-bcm2835',
        owner  => 'root',
        group  => 'root',
        mode   => '755'
    } ->
    exec { 'install-bcm2835':
        command  => '/usr/bin/install-bcm2835',
        creates  => '/usr/local/include/bcm2835.h',
        provider => 'shell'
    }

    package { 'wiringpi':
        ensure => installed
    }
    package { 'spidev':
        ensure => installed,
        provider => 'pip3'
    }
}
