class nanoc {
    Nanoc {} -> Nanoc::Site <| |>

    file { '/var/nanoc-sites':
        ensure => directory,
        owner  => 'root',
        group  => 'root'
    }
}
