class ubutils::dconf {

    exec { 'dconf-update':
        command  => '/usr/bin/dconf update',
        refreshonly => true,
        user => 'root',
        group => 'root'
    }

    file { "/etc/dconf/db/wooliedconfdefault.d":
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root'
    }
    -> file { "/etc/dconf/db/wooliedconfdefault.d/00-wooliedconfdefaults":
        source  => 'puppet:///modules/ubutils/00-wooliedconfdefaults',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Exec['dconf-update']
    }
}
