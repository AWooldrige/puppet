class pihole {

    # TODO: set /etc/pihole/setupVars.conf and work out how to install this
    # unattended. For now, pihole has to be installed manually after the puppet
    # run. This is sad I know, but they don't provide any packages, just a
    # script to run.  https://docs.pi-hole.net/main/basic-install/

    package { 'lighttpd':
        ensure => installed,
    }

    file { "/etc/lighttpd/external.conf":
        source => 'puppet:///modules/pihole/lighttpd-external.conf',
        owner => 'root',
        group => 'root',
        mode => '0644',
        require => Package['lighttpd'],
        notify => Service['lighttpd']
    }

    service { 'lighttpd':
        ensure     => running,
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        require => Package['lighttpd']
    }

    file { "/etc/nginx/cg.wooldrige.co.uk.d/pihole.conf":
        source => 'puppet:///modules/pihole/pihole-nginx.conf',
        owner => 'root',
        group => 'root',
        mode => '0644',
        require => File["/etc/nginx/cg.wooldrige.co.uk.d"],
        notify => Service['nginx']
    }
}
