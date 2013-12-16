class locale {
    package { 'locales':
        ensure => installed
    }
    file { '/etc/default/locale':
        source => 'puppet:///modules/locale/locale',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['locales'],
        notify  => Exec['locale-reconfigure']
    }
    exec { 'locale-reconfigure':
        refreshonly => true,
        command     => 'locale-gen en_GB.UTF-8 && dpkg-reconfigure locales',
        path        => [
            '/usr/local/bin',
            '/opt/local/bin',
            '/usr/bin',
            '/usr/sbin',
            '/bin',
            '/sbin' ],
        require => Package['locales']
    }
}
