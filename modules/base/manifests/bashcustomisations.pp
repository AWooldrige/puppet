class base::bashcustomisations {

    file { '/etc/custom.bashrc':
        source  => 'puppet:///modules/base/custom.bashrc',
        owner   => 'root',
        group   => 'root',
        mode    => '0644'
    }
    file { '/root/.bashrc':
        ensure  => link,
        target  => '/etc/custom.bashrc',
        require => File['/etc/custom.bashrc']
    }

}
