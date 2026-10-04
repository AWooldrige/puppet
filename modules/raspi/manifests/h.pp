class raspi::h {

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
    file { '/srv/kitchen':
        ensure  => 'directory',
        owner   => 'woolie',
        group   => 'www-data',
        mode    => '2750',
        require => User['woolie']
    }
    file { '/etc/nginx/h.wooldrige.co.uk.d/kitchen-data.conf':
        source  => 'puppet:///modules/raspi/kitchen-data.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => [
            File['/etc/nginx/h.wooldrige.co.uk.d'],
            File['/etc/nginx/conf.d/client-authorisation.conf']
        ],
        notify  => Exec['reload-nginx']
    }

    file { "/etc/nginx/sites-available/h.wooldrige.co.uk":
        source  => 'puppet:///modules/raspi/sites-available/h.wooldrige.co.uk',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        require => [
            Package['nginx'],
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
