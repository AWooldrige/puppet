class base::utilitylibs {

    file { '/usr/share/wpu':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    } ->
    file { '/usr/share/wpu/wpu_shell':
        source => 'puppet:///modules/base/wpu_shell',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }
}
