class raspi::boot-configuration {

    file { '/boot/config.txt':
        source  => 'puppet:///modules/raspi/config.txt',
        owner   => 'root',
        group   => 'root',
        mode    => '0755'
    }

}
