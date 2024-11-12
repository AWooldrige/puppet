class toggles {

    file { '/etc/toggles.toml':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',

        # Puppet uses the first one which exists
        source => [
             "puppet:///modules/toggles/toggles.toml.${::facts['networking']['hostname']}",
             "puppet:///modules/toggles/toggles.toml"
        ]
    }
}
