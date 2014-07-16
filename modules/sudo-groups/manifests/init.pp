class sudo-groups {

    package { 'sudo':
        ensure => installed
    }

    group { ['passwordsudo', 'nopasswordsudo']:
        ensure => present
    }

    file { '/etc/sudoers.d/sudo-based-on-group':
        source  => 'puppet:///modules/sudo-groups/sudo-based-on-group',
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        require => Package['sudo']
    }

}
