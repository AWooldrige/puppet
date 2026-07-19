class raspi::bootconfig {

    # Enable 1-wire on GPIO4 (header pin 7) for the DS18B20 temp sensors; SPI is owned by raspi::spi.
    file_line { 'Enable 1-wire for DS18B20 sensors':
        path => '/boot/firmware/config.txt',
        line => 'dtoverlay=w1-gpio,gpiopin=4,pullup=0',
    }
}
