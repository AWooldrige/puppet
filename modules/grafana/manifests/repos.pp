class grafana::repos {

    include apt

    apt::source{ 'grafana':
        comment  => 'Grafana repos',
        location => 'https://apt.grafana.com',
        repos => 'main',
        release => 'stable',
        key => {
            'name' => 'grafana.asc',
            'source' => 'https://apt.grafana.com/gpg.key',
        },
        notify => Exec['apt_update']
    }
}
