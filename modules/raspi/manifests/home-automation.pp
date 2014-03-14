class raspi::home-automation {

    #Install wiringPi: Git shallow clone, call build, delete directory

    #Install wiringPi
    $cmd = 'git clone git://git.drogon.net/wiringPi && cd wiringPi && ./build'
    exec { 'install-wiringpi-manually':
        creates => '/usr/local/lib/libwiringPi.so',
        command => $cmd,
        cwd => '/tmp/'
        user => 'woolie',
        path        => [ '/usr/local/bin', '/opt/local/bin', '/usr/bin',
                         '/usr/sbin', '/bin', '/sbin' ],
        require   => [Package['openssl'],
                      File['/etc/nginx/ssl'],
                      Class['user-woolie']]
    }

    #Install 433Utils
    $cmd = 'git clone TODO && cd wiringPi && ./build'
    exec { 'install-433utils-manually':
        #creates => '/usr/local/lib/libwiringPi.so',
        #command => $cmd,
        #cwd => '/tmp/'
        user => 'woolie',
        path     => [ '/usr/local/bin', '/opt/local/bin', '/usr/bin',
                         '/usr/sbin', '/bin', '/sbin' ],
        require   => Exec['install-wiringpi-manually']
    }

    #Generate server certificate and private key
    file { '/etc/nginx/ssl':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Class['nginx']
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

    package { ['flask-login', 'flask-sqlalchemy']:
        ensure   => installed,
        provider => pip
    }
}
