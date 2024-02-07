class locale {
    package { 'locales':
        ensure => installed
    }
    file { ['/etc/default/locale', '/etc/locale.conf']:
        source => 'puppet:///modules/locale/locale',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['locales']
    }

    #exec { 'locale-reconfigure':
    #    command     => '/usr/sbin/locale-gen en_GB.UTF-8',
    #    refreshonly => true,
    #    require     => Package['locales']
    #}
}
