class raspi::cpugovernor {

    file { '/etc/tmpfiles.d/cpu-governor.conf':
        ensure => 'file',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => "puppet:///modules/raspi/cpu-governor/cpu-governor.conf.${facts['networking']['hostname']}",
    } ~>
    exec { 'Apply the CPU governor':
        command     => '/usr/bin/systemd-tmpfiles --create /etc/tmpfiles.d/cpu-governor.conf',
        refreshonly => true,
    }
}
