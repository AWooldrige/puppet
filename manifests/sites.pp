$extlookup_datadir = "/root/extlookup/"
$extlookup_precedence = ["nodes/%{hostname}", "common"]

node default {
    $enhancers = [
        "tree",
        "strace",
        "ack-grep",
        "iotop",
        "man-db",
        "makepasswd",
        "curl"
    ]
    package { $enhancers:
        ensure => installed
    }
    $notneeded = [
        "ack",
    ]
    package { $notneeded:
        ensure => purged
    }

    # Alias ack to ack-grep
    exec { "/bin/ln -sf /usr/bin/ack-grep /usr/local/bin/ack":
        unless => "/bin/sh -c '[ -L /usr/local/bin/ack ]'",
        require => Package['ack-grep']
    }

    file { '/root/extlookup':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '400',
    }
    file { '/root/extlookup/common.csv':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '400',
    }

    include user-woolie
    include puppet-auto-update
    include ntp
    include tmux
    include vim
    include sudo
    include sshd
    include bash
}
node default-server inherits default {
    include zend-framework
    include mysql
    include woolie-co-uk

    class { 'httpd' :
    }

    /**
     * authz_groupfile and authz_host are needed otherwise the Order statement
     * isn't available
     */
    $enabled = [
        'rewrite',
        'authz_groupfile',
        'authz_host',
        'ssl',
        'alias'
    ]
    $disabled = [
        'cgi',
        'authz_default',
        'auth_basic',
        'authz_user',
        'autoindex',
        'authn_file'
    ]
    httpd::module { $enabled:
        ensure => enabled
    }
    httpd::module { $disabled:
        ensure => disabled
    }

}

node default-desktop inherits default {
    include gvim
    include devtools
    include standard-desktop
}
node development-desktop inherits default-desktop {

    include zend-framework
    include mysql
    include woolie-co-uk

    class { 'httpd' :
    }

    /**
     * authz_groupfile and authz_host are needed otherwise the Order statement
     * isn't available
     */
    $enabled = [
        'rewrite',
        'authz_groupfile',
        'authz_host',
        'ssl',
        'alias'
    ]
    $disabled = [
        'cgi',
        'authz_default',
        'auth_basic',
        'authz_user',
        'autoindex',
        'authn_file'
    ]
    httpd::module { $enabled:
        ensure => enabled
    }
    httpd::module { $disabled:
        ensure => disabled
    }
}


node "agw-nc10" inherits development-desktop {
}
node "agw-inspiron-1720" inherits development-desktop {
}
node "dev-vm" inherits default-desktop {
}

node "metis.woolie.co.uk" inherits default-server {
}
node "eros.woolie.co.uk" inherits default-server {
}
node "devvm.woolie.co.uk" inherits default-server {
}
node "hera.woolie.co.uk" inherits default-server {
}
node "dev.local" inherits default-server {
}
