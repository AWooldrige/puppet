class raspi::hass {

    certbot::cert { 'hass.h.wooldrige.co.uk':
        ensure => 'installed',
        extraargs => ' -d hass.h.wooldrige.co.uk'
    }

    file { "/etc/nginx/sites-available/hass.h.wooldrige.co.uk":
        source  => 'puppet:///modules/raspi/sites-available/hass.h.wooldrige.co.uk',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        require => [
            Package['nginx'],
            Exec['Check manually added credentials file is present for h (from LastPass)'],
            Certbot::Cert['hass.h.wooldrige.co.uk'],
            File['/var/www/h.wooldrige.co.uk/noauth/auth_required.html']
        ],
        notify => Exec['reload-nginx']
    } ->
    file { "/etc/nginx/sites-enabled/hass.h.wooldrige.co.uk":
        ensure => 'link',
        target => '/etc/nginx/sites-available/hass.h.wooldrige.co.uk',
        notify => Exec['reload-nginx']
    }
}
