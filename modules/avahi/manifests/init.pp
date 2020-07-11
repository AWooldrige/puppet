class avahi {
    package { 'avahi-daemon':
        ensure => installed
    } ->
    service { 'avahi-daemon':
        ensure     => running,
        enable     => true
    }
}
