class raspi::spi {

    file_line { 'Enable SPI in Raspberry PI BIOS equiv':
        path => '/boot/firmware/usercfg.txt',
        line => 'dtparam=spi=on',
    } ->
    file { '/usr/bin/install-bcm2835':
        source => 'puppet:///modules/raspi/home-automation/install-bcm2835',
        owner  => 'root',
        group  => 'root',
        mode   => '755'
    } ->
    exec { 'install-bcm2835':
        command => '/usr/bin/install-433utils',
        user    => 'woolie',
        path    => ['/usr/local/bin', '/opt/local/bin', '/usr/bin',
                    '/usr/sbin', '/bin', '/sbin' ]
    }
}
