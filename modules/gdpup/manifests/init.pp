class gdpup {

    file { '/usr/local/sbin/gdpup':
        source => 'puppet:///modules/gdpup/gdpup',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    } ->
    cron { 'Full puppet run once per night':
        command => '/usr/local/sbin/gdpup -f',
        user    => root,
        hour    => 3,
        minute  => 15
    } ->
    cron { 'Check for git updates once per hour':
        command => '/usr/local/sbin/gdpup -f',
        user    => root,
        hour    => absent,
        minute  => 39
    }

}
