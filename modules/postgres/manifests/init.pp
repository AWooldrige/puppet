class postgres {
    package { ['postgresql', 'postgresql-contrib']:
        ensure => installed
    } ->
    service { 'postgresql':
        ensure     => running,
        enable     => true
    }
}
