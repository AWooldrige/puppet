class onmyplate-co-uk {

    $wp_id = 'ompcouk'

    $theme_version = '0.1.0'
    exec { "download-omp-theme-${theme_version}":
        command => "curl -L -o /opt/local-zips/omp-theme-${theme_version}.zip https://dl.dropbox.com/s/xsqjfy1logosbmg/omp-theme-${theme_version}.zip?dl=1",
        creates => "/opt/local-zips/omp-theme-${theme_version}.zip",
        require => File['/opt/local-zips']
    }

    $plugin_version = '0.1.0'
    exec { "download-omp-plugin-${plugin_version}":
        command => "curl -L -o /opt/local-zips/omp-plugin-${plugin_version}.zip https://dl.dropbox.com/s/2plzzb89m2q3a2i/omp-plugin-${plugin_version}.zip?dl=1",
        creates => "/opt/local-zips/omp-plugin-${plugin_version}.zip",
        require => File['/opt/local-zips']
    }

    wordpress::instance { $wp_id:
        ensure  => "3.5",
        domain  => "onmyplate.co.uk",
        backups => true,
        http_port => 81
    }

    wordpress::theme { "${wp_id}:omp-theme-${theme_version}":
        ensure => 'installed',
        active => true,
        source_file => "/opt/local-zips/omp-theme-${theme_version}.zip",
        require => [
            Wordpress::Instance[$wp_id],
            Exec["download-omp-theme-${theme_version}"] ]
    }
    wordpress::plugin { "${wp_id}:omp-plugin-${plugin_version}":
        ensure => 'installed',
        active => true,
        source_file => "/opt/local-zips/omp-plugin-${plugin_version}.zip",
        require => [
            Wordpress::Instance[$wp_id],
            Exec["download-omp-plugin-${plugin_version}"] ]
    }
}
