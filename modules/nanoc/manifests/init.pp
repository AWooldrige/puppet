class nanoc {
    Nanoc {} -> Nanoc::Site <| |>

    file { ['/var/nanoc', '/var/nanoc/content', '/var/nanoc/nginx-config']:
        ensure => directory,
        owner  => 'root',
        group  => 'root'
    }
}
