class docker::repos {

    include apt

    apt::source{ 'docker':
        comment  => 'Docker engine repo',
        location => 'https://download.docker.com/linux/ubuntu',
        repos    => 'stable',
        key      => {
            'name'   => 'docker.asc',
            'source' => 'https://download.docker.com/linux/ubuntu/gpg',
        },
        notify => Exec['apt_update']
    }
}
