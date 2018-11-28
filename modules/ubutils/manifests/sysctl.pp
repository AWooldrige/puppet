class ubutils::sysctl {

    # $ tail -n 2 /etc/sysctl.d/README.sysctl
    # After making any changes, please run "service procps reload"

    service { 'procps':
        ensure     => running
    }

    file { "/etc/sysctl.d/60-sysctldesktopsettings.conf":
        source  => 'puppet:///modules/ubutils/60-sysctldesktopsettings.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Service['procps']
    }
}
