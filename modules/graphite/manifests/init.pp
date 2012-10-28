class graphite ($httpd_port = 80) {

    $graphiteDebDeps = [ 'python-pip', 'python-dev', 'libapache2-mod-wsgi',
                         'python-twisted-core', 'python-django', 'python-cairo']

    package { $graphiteDebDeps:
        ensure => installed
    }

    package { ['django-tagging', 'whisper']:
        require => Package[$graphiteDebDeps],
        ensure  => installed,
        provider => pip
    }

    file {"/var/log/apache2/graphite":
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '750'
    }
    file {"/var/run/wsgi":
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '755'
    }
    file {"/opt/graphite/conf/graphite.wsgi":
        ensure  => present,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '400',
        content => template("graphite/graphite.wsgi.erb"),
        require => Exec['graphite-web-install']
    }
    file {"/etc/apache2/sites-available/graphite":
        ensure  => present,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '400',
        content => template("graphite/apache-virtualhost.erb"),
        require => Package['apache2'],
        notify  => Service['apache2']
    }

    /*
     * Annoyingly, we can't use the PIP package provider with these two, as they
     * don't register with PIP when correctly installed. I.e. You can keep
     * doing a pip install carbon and it'll try to install every time
     */
    exec { "carbon-install":
        command => "pip install carbon",
        require => Package[[ 'python-pip', 'whisper', 'python-dev' ]],
        creates => "/opt/graphite/bin/carbon-cache.py",
        path => ["/usr/bin", "/usr/sbin"],
        timeout => 100
    }
    exec { "graphite-web-install":
        command => "pip install graphite-web",
        require => [ Package['django-tagging'], Package[$graphiteDebDeps], Exec['carbon-install'] ],
        creates => "/opt/graphite/bin/build-index.sh",
        path => ["/usr/bin", "/usr/sbin"],
        notify => Exec['graphite-install-db'],
        timeout => 100
    }

    file { '/opt/graphite/conf/carbon.conf':
        ensure => present,
        owner => 'root',
        group => 'root',
        mode => 700,
        content => template('graphite/carbon.conf.erb'),
        notify => Exec['carbon-service'],
        require => Exec['graphite-web-install']
    }
    file { '/opt/graphite/conf/storage-schemas.conf':
        ensure => present,
        owner => 'root',
        group => 'root',
        mode => 700,
        content => template('graphite/storage-schemas.conf.erb'),
        notify => Exec['carbon-restart'],
        require => Exec['carbon-install']
    }

    exec { "graphite-install-db":
        command => "python /opt/graphite/webapp/graphite/manage.py syncdb --noinput",
        require => Exec['graphite-web-install'],
        creates => "/opt/graphite/storage/graphite.db",
        path    => "/usr/bin"
    }

    httpd::module { "wsgi":
        ensure => enabled
    }

    httpd::site { 'graphite':
        ensure => enabled,
        require => File["/etc/apache2/sites-available/graphite"]
    }


    #TODO make this on startup
    exec { "carbon-service":
        path => "/opt/graphite/bin",
        command => "carbon-cache.py start",
        unless => "carbon-cache.py status",
        require => Exec['carbon-install'],
    }

    exec { "carbon-restart":
        path => "/opt/graphite/bin",
        command => "carbon-cache.py restart",
        refreshonly => true,
        require => [ Exec['carbon-install'], Exec['carbon-service'] ]
    }
}

