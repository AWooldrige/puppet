class tmux {
    package { 'tmux':
        ensure => installed,
    }
    file { '/etc/tmux.conf':
        source  => 'puppet:///modules/tmux/tmux.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '644',
        require => Package['tmux'],
    }
}
