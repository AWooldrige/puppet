class sshd {
    group { 'sshallowedlogin':
        ensure => present,
    }
    package { 'openssh-server':
        ensure => installed,
    }
    file { '/etc/ssh/sshd_config':
        source  => 'puppet:///modules/sshd/sshd_config',
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => [Package['openssh-server'], Group['sshallowedlogin']]
    }
    service { 'ssh':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        enable     => true,
        require    => File['/etc/ssh/sshd_config']
    }
}
