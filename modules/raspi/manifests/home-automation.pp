class raspi::home-automation {

    package { ['openssl']:
        ensure => installed
    }

    file { '/usr/bin/install-wiringpi':
        source => 'puppet:///modules/raspi/home-automation/install-wiringpi',
        owner  => 'root',
        group  => 'root',
        mode   => '755'
    }
    exec { 'install-wiringpi':
        creates => '/usr/local/lib/libwiringPi.so',
        command => '/usr/bin/install-wiringpi',
        user    => 'woolie',
        path    => [ '/usr/local/bin', '/opt/local/bin', '/usr/bin',
                         '/usr/sbin', '/bin', '/sbin' ],
        require => [File['/usr/bin/install-wiringpi'],
                    Package['openssl'],
                    File['/etc/nginx/ssl'],
                    Class['user-woolie']]
    }
    file { '/usr/bin/install-433utils':
        source => 'puppet:///modules/raspi/home-automation/install-433utils',
        owner  => 'root',
        group  => 'root',
        mode   => '755'
    }
    exec { 'install-433utils':
        creates => '/usr/bin/RFSniffer',
        command => '/usr/bin/install-433utils',
        user    => 'woolie',
        path    => ['/usr/local/bin', '/opt/local/bin', '/usr/bin',
                    '/usr/sbin', '/bin', '/sbin' ],
        require => [File['/usr/bin/install-433utils'],
                    Exec['install-wiringpi']]
    }

    #Generate server certificate and private key
    file { '/etc/nginx/ssl':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package['nginx']
    }
    $command = "openssl req -new -newkey rsa:2048 -x509 -days 3650 -nodes \
                -out /etc/nginx/ssl/self-signed-server.crt \
                -keyout /etc/nginx/ssl/server.key  -subj \
                '/C=UK/ST=UK/L=PI/O=Personal/OU=PI/CN=home.wooldrige.co.uk'"
    exec { 'create-self-signed-server-certificate':
        creates => '/etc/nginx/ssl/self-signed-server.crt',
        command     => $command,
        path        => [ '/usr/local/bin', '/opt/local/bin', '/usr/bin',
                         '/usr/sbin', '/bin', '/sbin' ],
        require   => [ Package['openssl'], File['/etc/nginx/ssl']]
    }

    #Allow www-data to call codesend
    file { '/etc/sudoers.d/home-automation-www-data':
        source => 'puppet:///modules/raspi/home-automation/sudoers-www-data',
        owner  => 'root',
        group  => 'root',
        mode   => '440'
    }

    #Place to store .htpasswd
    file { '/etc/nginx/authfiles':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package['nginx']
    }

    #Add nginx config that is dependant on the server cert and private key
    file { '/etc/nginx/sites-enabled/home-automation.conf':
        source  => 'puppet:///modules/raspi/home-automation/nginx.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Exec['create-self-signed-server-certificate'],
        notify  => Service['nginx']
    }

    #Install uwsgi package and python plugin
    package { ['uwsgi', 'uwsgi-plugin-python']:
        ensure => installed
    }
    #Add uwsgi configuration
    file { '/etc/uwsgi/apps-enabled/home-automation.ini':
        source  => 'puppet:///modules/raspi/home-automation/uwsgi-config.ini',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => [ Package['uwsgi-plugin-python'] ]
    }
    service { 'uwsgi':
        ensure  => running,
        require => File['/etc/uwsgi/apps-enabled/home-automation.ini']
        #Get this running on startup
    }
}
