class nanoc {

    file { ['/var/nanoc',
            '/var/nanoc/content',
            '/var/nanoc/nginx-config',
            '/var/nanoc/repos',
            '/var/log/nanoc']:
        ensure => directory,
        owner  => 'root',
        group  => 'root'
    }
}
