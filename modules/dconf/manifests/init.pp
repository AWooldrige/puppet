class dconf {

    # Not needed, but handy.
    package { 'dconf-editor':
        ensure => installed
    }

    # The specific dirname of 'local.d' is important. dconf update will treat
    # this as the keyfiles source, then create the binary 'local' database that
    # is referenced in /etc/dconf/profile/user
    file { "/etc/dconf/db/local.d":
        ensure => 'directory',
        owner   => root,
        group   => root
    }

    file { "/etc/dconf/db/local.d/01-general-all-machines":
        source  => 'puppet:///modules/dconf/01-general-all-machines',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Exec['dconf-update'],
        require => File["/etc/dconf/db/local.d"]
    }

    # The specific filename of 'user' is important. See TODO
    file { "/etc/dconf/profile/user":
        source  => 'puppet:///modules/dconf/profile',
        owner   => root,
        group   => root,
        require => File["/etc/dconf/db/local.d/01-general-all-machines"]
    }

    exec { 'dconf-update':
        command  => '/usr/bin/dconf update',
        refreshonly => true
    }
}
