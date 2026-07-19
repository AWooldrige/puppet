class sshd {
    group { 'sshallowedlogin':
        ensure  => present,
        gid     => 19003
    }
    package { 'openssh-server':
        ensure => installed,
    }

    if $facts['os']['release']['major'] == '11' {
        $sshd_config_source = "puppet:///modules/sshd/sshd_config_old_raspbian11"
    }
    else {
        $sshd_config_source = "puppet:///modules/sshd/sshd_config"
    }

    file { '/etc/ssh/sshd_config':
        source       => $sshd_config_source,
        owner        => 'root',
        group        => 'root',
        mode         => '0644',
        validate_cmd => '/usr/sbin/sshd -t -f %',
        require      => [Package['openssh-server'], Group['sshallowedlogin']],
        notify       => Service['ssh'],
    }

    exec { 'Disable ssh.socket in favour of ssh.service':
        command => '/usr/bin/systemctl disable --now ssh.socket',
        onlyif  => '/usr/bin/systemctl is-active --quiet ssh.socket',
        require => Package['openssh-server'],
        before  => Service['ssh'],
    }

    service { 'ssh':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        enable     => true,
        require    => File['/etc/ssh/sshd_config']
    }
}
