node default {

    $enhancers = [
        "tree",
        "strace",
        "ack-grep",
        "iotop"
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
    class { 'httpd' :
        http_port => 80,
        https_port => 443
    }

    /**
     * authz_groupfile and authz_host are needed otherwise the Order statement
     * isn't available
     */
    $enabled = [
        'rewrite',
        'authz_groupfile',
        'authz_host',
        'ssl'
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

    httpd::site { 'default':
        ensure => enabled
    }
}

node default-desktop inherits default {
    include gvim
    include devtools
    include standard-desktop
}
node development-desktop inherits default-desktop {

    include zend-framework

    class { 'httpd' :
        http_port => 80,
        https_port => 443
    }

    /**
     * authz_groupfile and authz_host are needed otherwise the Order statement
     * isn't available
     */
    $enabled = [
        'rewrite',
        'authz_groupfile',
        'authz_host',
        'ssl'
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

    httpd::site { 'default':
        ensure => enabled
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
node "dev.local" inherits default-server {
}
