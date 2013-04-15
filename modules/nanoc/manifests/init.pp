class nanoc {
    Nanoc {} -> Nanoc::Site <| |>

    file { '/etc/nginx/conf.d/nanoc-sites':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        require => Package['nginx']
    }
    file { '/var/nanoc-sites':
        ensure => directory,
        owner  => 'root',
        group  => 'root'
    }
    file { '/var/log/nginx/nanoc-sites':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        require => Package['nginx']
    }
}
