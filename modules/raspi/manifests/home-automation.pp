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
