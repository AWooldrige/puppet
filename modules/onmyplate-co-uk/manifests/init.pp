class onmyplate-co-uk {

    $wp_id = 'ompcouk'

    $theme_version = '0.4.0'
    exec { "download-omp-theme-${theme_version}":
        command => "curl -L -o /opt/local-zips/omp-theme-${theme_version}.zip https://s3-eu-west-1.amazonaws.com/woolie-releases/wp_ompcouk/omp-theme-${theme_version}.zip",
        creates => "/opt/local-zips/omp-theme-${theme_version}.zip",
        require => File['/opt/local-zips']
    }

    $plugin_version = '0.3.0'
    exec { "download-omp-plugin-${plugin_version}":
        command => "curl -L -o /opt/local-zips/omp-plugin-${plugin_version}.zip https://s3-eu-west-1.amazonaws.com/woolie-releases/wp_ompcouk/omp-plugin-${plugin_version}.zip",
        creates => "/opt/local-zips/omp-plugin-${plugin_version}.zip",
        require => File['/opt/local-zips']
    }

    wordpress::instance { $wp_id:
        ensure  => "3.5.1",
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
    wordpress::plugin { [
            "${wp_id}:omp-plugin-0.1.0",
            "${wp_id}:omp-plugin-0.2.0"]:
        ensure => "removed",
        require => Wordpress::Instance[$wp_id],
        before => Wordpress::Theme["${wp_id}:omp-theme-${theme_version}"]
    }
    wordpress::plugin { "${wp_id}:omp-plugin-${plugin_version}":
        ensure => 'installed',
        active => true,
        source_file => "/opt/local-zips/omp-plugin-${plugin_version}.zip",
        require => [
            Wordpress::Instance[$wp_id],
            Wordpress::Plugin["${wp_id}:omp-plugin-0.1.0"],
            Exec["download-omp-plugin-${plugin_version}"] ]
    }
}
