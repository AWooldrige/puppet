class raspi::cg {

    exec { 'Check manually added credentials file is present for cg (from LastPass)':
       command => '/bin/echo "WARNING: YOU MUST MANUALLY ADD .htpasswd FILE FOR CG"',
       unless  => '/usr/bin/test -f /etc/nginx/secrets/cg.htpasswd',
    }

    exec { 'Certificate for cg.wooldrige.co.uk':
        creates => '/etc/letsencrypt/live/cg.wooldrige.co.uk/privkey.pem',
        command => '/usr/bin/certbot certonly --noninteractive --agree-tos -m certificates@wooldrige.co.uk -d cg.wooldrige.co.uk --webroot -w /var/www/letsencrypt',
        require => [
            Package['certbot'],
            Service['nginx']
        ],
        notify => Exec['reload-nginx'],
        tries => 3,
        try_sleep => 30
    }

    file { "/etc/nginx/cg.wooldrige.co.uk.d":
        ensure => 'directory',
        owner   => 'root',
        group   => 'root'
    }->
    file { "/var/www/cg.wooldrige.co.uk":
        ensure => 'directory',
        owner   => 'root',
        group   => 'www-data'
    }->
    file { "/var/www/cg.wooldrige.co.uk/noauth":
        ensure => 'directory',
        owner   => 'root',
        group   => 'www-data'
    }->
    file { "/var/www/cg.wooldrige.co.uk/noauth/auth_required.html":
        source  => 'puppet:///modules/raspi/auth_required.html',
        owner  => 'root',
        group  => 'www-data',
        mode   => '0644'
    }->
    file { "/etc/nginx/sites-available/cg.wooldrige.co.uk":
        source  => 'puppet:///modules/raspi/sites-available/cg.wooldrige.co.uk',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        require => [
            Package['nginx']
        ],
        notify  => Service['nginx']
    } ->
    file { "/etc/nginx/sites-enabled/cg.wooldrige.co.uk":
        ensure => 'link',
        target => '/etc/nginx/sites-available/cg.wooldrige.co.uk',
        notify  => Service['nginx']
    }
}
