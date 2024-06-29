class sudo {

    package { 'sudo':
        ensure => installed
    }

    group { 'passwordsudo':
        ensure  => present,
        gid     => 19001
    }

    group { 'nopasswordsudo':
        ensure  => present,
        gid     => 19002
    }

    file { '/etc/sudoers.d/sudo-based-on-group':
        source  => 'puppet:///modules/sudo/sudo-based-on-group',
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        require => [ Package['sudo'],
                     Group['passwordsudo'],
                     Group['nopasswordsudo'] ]
    }

    file { '/etc/polkit-1/rules.d/61-woolie-admin.rules':
        source  => 'puppet:///modules/sudo/61-woolie-admin.rules',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => [Group['passwordsudo'], Group['nopasswordsudo']]
    }
}
