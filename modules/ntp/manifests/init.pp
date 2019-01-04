class ntp {

    file { '/etc/systemd/timesyncd.conf':
        source  => 'puppet:///modules/ntp/timesyncd.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Service['systemd-timesyncd']
    } ->
    service { 'systemd-timesyncd':
        ensure     => running,
        enable     => true
    } ->
    exec { 'Set correct timezone':
        command  => "timedatectl set-timezone Europe/London",
        unless => "timedatectl status | grep 'Time zone: Europe/London'",
        provider => "shell"
    } ->
    exec { 'Make sure NTP running':
        command  => "timedatectl set-timezone Europe/London",
        unless => "timedatectl status | grep 'Network time on: yes'",
        provider => "shell"
    }

}
