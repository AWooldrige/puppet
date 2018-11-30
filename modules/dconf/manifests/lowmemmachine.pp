class dconf::lowmemmachine {

    file { "/etc/dconf/db/local.d/11-lowmem-machine":
        source  => 'puppet:///modules/dconf/11-lowmem-machine',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Exec['dconf-update'],
        require => File["/etc/dconf/db/local.d"]
    }
}
