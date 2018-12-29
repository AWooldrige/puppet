class ubutils::epsonscanner {
    # Epson V330 photo scanner

    package { 'libsane1':
        ensure => installed,
    }

    file { "/etc/udev/rules.d/80-epsonv330.rules":
        source  => 'puppet:///modules/ubutils/80-epsonv330.rules',
        owner   => 'root',
        group   => 'root',
        mode    => '0644'
    }

    # Next manually install iscan DEB from:
    # http://support.epson.net/linux/en/iscan_c.html

    # Then create the symbolic links as shown in
    # https://www.ryananddebi.com/2018/05/26/linux-fixing-the-epson-v33-perfection-scanner-issue-in-kubuntu-18-04/
}
