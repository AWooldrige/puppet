class httpd::status ($status_port=8000) {

    # Disable the default mod_status configuration, then enable mod_status
    file { '/etc/apache2/mods-available/status.conf':
        source  => 'puppet:///modules/httpd/status.conf',
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0400',
        notify  => Service['apache2']
    }
    httpd::module { 'status':
       ensure  => enabled,
       require => File['/etc/apache2/mods-available/status.conf']
    }

    # VHost and Diamond collector
    file { '/etc/apache2/sites-available/status':
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0400',
        content => template('httpd/vhosts/status'),
        notify  => Service['apache2']
    }
    httpd::site { 'status':
        ensure => enabled
    }
    file { '/etc/diamond/collectors/HttpdCollector.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('httpd/diamond/HttpdCollector.conf')
    }
}
