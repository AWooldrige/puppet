class sshd {
    group { "sshallowedlogin":
        ensure  => present,
    }
    package { 'openssh-server':
        ensure => latest,
    }
    file { '/etc/ssh/sshd_config':
        source  => 'puppet:///modules/sshd/sshd_config',
        owner   => 'root',
        group   => 'root',
        mode    => '600',
        require => [Package['openssh-server'], Group['sshallowedlogin']],
        notify  => Service['ssh']
    }
    service { "ssh":
        ensure => running,
        hasstatus => true,
        hasrestart => true,
        enable => true,
        require => File['/etc/ssh/sshd_config']
    }

}
