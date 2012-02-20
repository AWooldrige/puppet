class gvim {
    package { 'gvim-gnome':
        ensure => latest,
    }
    file { '/etc/vim/gvimrc.local':
        source  => 'puppet:///modules/gvim/gvimrc.local',
        owner   => 'root',
        group   => 'root',
        mode    => '644',
        require => Package['gvim-gnome'],
    }
}
