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
        mode    => '644',
        require => [Package['openssh-server'], Group['sshallowedlogin']]
    }
}
