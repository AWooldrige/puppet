class locale {

    package { 'locales':
        ensure => installed
    }

    file_line { 'Enable en_GB.UTF-8 in locale.gen':
        ensure  => present,
        path    => '/etc/locale.gen',
        line    => 'en_GB.UTF-8 UTF-8',
        match   => '^#?\s*en_GB\.UTF-8 UTF-8',
        require => Package['locales'],
        notify  => Exec['locale-gen'],
    }

    exec { 'locale-gen':
        command     => '/usr/sbin/locale-gen',
        refreshonly => true,
        require     => Package['locales'],
    }

    # Manage only /etc/default/locale (Ubuntu reads it via PAM); systemd's /etc/locale.conf is unused on Ubuntu.
    file { '/etc/default/locale':
        source  => 'puppet:///modules/locale/locale',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Exec['locale-gen'],
    }
}
