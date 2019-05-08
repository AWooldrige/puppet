class gdpup {

    file { '/usr/local/sbin/gdpup':
        source => 'puppet:///modules/gdpup/gdpup',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    } ->
    cron { 'Full puppet run once per night':
        command => '/usr/bin/systemd-cat -t "gdpup" /usr/local/sbin/gdpup -f',
        user    => root,
        hour    => 5,
        minute  => 15
    } ->
    cron { 'Check for updates regularly, only run puppet if changed':
        command => '/usr/bin/systemd-cat -t "gdpup" /usr/local/sbin/gdpup',
        user    => root,
        hour    => absent,
        minute  => [19, 39]
    }

}
