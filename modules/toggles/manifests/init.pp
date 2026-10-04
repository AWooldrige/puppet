class toggles {
    exec { 'Remove the toggles file Puppet used to manage':
        command => '/usr/bin/rm -f /etc/toggles.toml',
        onlyif  => '/usr/bin/grep -q "This file is controlled by Puppet" /etc/toggles.toml'
    } ->
    file { '/etc/toggles.toml':
        ensure  => 'file',
        replace => false,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/toggles/toggles.toml'
    }

    file { '/etc/profile.d/toggles-login.sh':
        ensure => 'file',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/toggles/toggles-login.sh'
    }
}
