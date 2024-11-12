class raspi::h {

    exec { 'Check manually added credentials file is present for h (from LastPass)':
       command => "/usr/bin/bash -c 'echo \"WARNING: YOU MUST MANUALLY ADD .htpasswd FILE FOR h\"; false'",
       unless  => '/usr/bin/test -f /etc/nginx/secrets/h.htpasswd',
    }

    certbot::cert { 'h.wooldrige.co.uk':
        ensure => 'installed',
        extraargs => ' -d websh1.h.wooldrige.co.uk'
    }

    file { "/etc/nginx/h.wooldrige.co.uk.d":
        ensure => 'directory',
        owner   => 'root',
        group   => 'root'
    }->
    file { "/var/www/h.wooldrige.co.uk":
        ensure => 'directory',
        owner   => 'root',
        group   => 'www-data'
    }->
    file { "/var/www/h.wooldrige.co.uk/index.html":
        source  => 'puppet:///modules/raspi/h.wooldrige.co.uk-webroot/index.html',
        owner  => 'root',
        group  => 'www-data',
        mode   => '0644'
    }->
    file { "/var/www/h.wooldrige.co.uk/noauth":
        ensure => 'directory',
        owner   => 'root',
        group   => 'www-data'
    }->
    file { "/var/www/h.wooldrige.co.uk/noauth/auth_required.html":
        source  => 'puppet:///modules/raspi/auth_required.html',
        owner  => 'root',
        group  => 'www-data',
        mode   => '0644'
    }->
    file { "/etc/nginx/sites-available/h.wooldrige.co.uk":
        source  => 'puppet:///modules/raspi/sites-available/h.wooldrige.co.uk',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        require => [
            Package['nginx'],
            Exec['Check manually added credentials file is present for h (from LastPass)'],
            Certbot::Cert['h.wooldrige.co.uk']
        ],
        notify => Exec['reload-nginx']
    } ->
    file { "/etc/nginx/sites-enabled/h.wooldrige.co.uk":
        ensure => 'link',
        target => '/etc/nginx/sites-available/h.wooldrige.co.uk',
        notify => Exec['reload-nginx']
    }
}
