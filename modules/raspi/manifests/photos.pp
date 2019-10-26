class raspi::photos {

    exec { 'Check manually added credentials file is present (from LastPass)':
       command => '/bin/echo "WARNING: YOU MUST MANUALLY ADD .htpasswd FILE FOR PHOTOS"',
       unless  => '/usr/bin/test -f /etc/nginx/secrets/photos.htpasswd',
    }

    exec { 'Certificate for photos.wooldrige.co.uk':
        creates => '/etc/letsencrypt/live/photos.wooldrige.co.uk/privkey.pem',
        command => '/usr/bin/certbot certonly --noninteractive --agree-tos -m certificates@wooldrige.co.uk -d photos.wooldrige.co.uk --webroot -w /var/www/letsencrypt',
        require => [
            Package['certbot'],
            Service['nginx']
        ],
        notify => Exec['reload-nginx'],
        tries => 3,
        try_sleep => 30
    }

    file { "/media/bulkstorage-fstab":
        ensure => 'directory',
        owner   => 'woolie',
        group   => 'www-data'
    }->
    file_line { 'Samsung portable USB hard drive':
        path => '/etc/fstab',
        line => 'UUID=2b103ac7-c7a6-4225-ac3b-47b42145f2ef /media/bulkstorage-fstab ext4 defaults,nofail,noatime 0 0'
    }->
    file { "/etc/nginx/sites-available/photos.wooldrige.co.uk":
        source  => 'puppet:///modules/raspi/sites-available/photos.wooldrige.co.uk',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        require => Package['nginx'],
        notify  => Service['nginx']
    } ->
    file { "/etc/nginx/sites-enabled/photos.wooldrige.co.uk":
        ensure => 'link',
        target => '/etc/nginx/sites-available/photos.wooldrige.co.uk',
        notify  => Service['nginx']
    }
}
