class raspi::photos {

    exec { 'Check manually added credentials file is present (from LastPass)':
       command => "/usr/bin/bash -c 'echo \"WARNING: YOU MUST MANUALLY ADD .htpasswd FILE FOR PHOTOS\"; false'",
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
    exec { 'Reload portable hard drive mount if not mounted':
       command => '/bin/mount -a',
       unless  => '/usr/bin/test -f /media/bulkstorage-fstab/jalbums-published/photos/index.html',
    } ->
    file { "/var/www/photos.wooldrige.co.uk":
        ensure => 'directory',
        owner   => 'root',
        group   => 'www-data'
    }->
    file { "/var/www/photos.wooldrige.co.uk/noauth":
        ensure => 'directory',
        owner   => 'root',
        group   => 'www-data'
    }->
    file { "/var/www/photos.wooldrige.co.uk/noauth/facebook_message.html":
        source  => 'puppet:///modules/raspi/facebook_message.html',
        owner  => 'root',
        group  => 'www-data',
        mode   => '0644'
    }->
    file { "/var/www/photos.wooldrige.co.uk/noauth/auth_required.html":
        source  => 'puppet:///modules/raspi/auth_required.html',
        owner  => 'root',
        group  => 'www-data',
        mode   => '0644'
    }->
    file { "/etc/nginx/sites-available/photos.wooldrige.co.uk":
        source  => 'puppet:///modules/raspi/sites-available/photos.wooldrige.co.uk',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        require => [
            Package['nginx'],
            Exec['Check manually added credentials file is present (from LastPass)'],
            Exec['Certificate for photos.wooldrige.co.uk']
        ],
        notify => Exec['reload-nginx']
    } ->
    file { "/etc/nginx/sites-enabled/photos.wooldrige.co.uk":
        ensure => 'link',
        target => '/etc/nginx/sites-available/photos.wooldrige.co.uk',
        notify => Exec['reload-nginx']
    }
}
