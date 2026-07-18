class raspi::bootconfig {

    file { '/boot/firmware/config.txt':
        source => 'puppet:///modules/raspi/config.txt',
        owner  => 'root',
        group  => 'root',
        mode   => '755'
    }
}
