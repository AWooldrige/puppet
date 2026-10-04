class raspi::bootconfig {

    # Enable 1-wire on GPIO4 (header pin 7) for the DS18B20 temp sensors.
    file_line { 'Enable 1-wire for DS18B20 sensors':
        ensure => $facts['networking']['hostname'] ? {
            'blrsh1' => 'present',
            default  => 'absent',
        },
        path   => '/boot/firmware/config.txt',
        line   => 'dtoverlay=w1-gpio,gpiopin=4,pullup=0',
    }

    if $facts['networking']['hostname'] == 'blrsh1' {
        file_line { 'Turn off Bluetooth on the boiler controller':
            path => '/boot/firmware/config.txt',
            line => 'dtoverlay=disable-bt',
        }
    }
}
