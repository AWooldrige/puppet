node default {

    $enhancers = ["tree",
                  "strace",
                  "ack",
                  "iotop"]
    package { $enhancers: ensure => "installed" }

    include user-woolie
    include puppet-auto-update
    include ntp
    include tmux
    include vim
    include sudo
    include sshd
}
node default-server inherits default {
    include zend-framework
    class { 'httpd' :
        http_port => 80,
        https_port => 443
    }
    $enabled = [ 'rewrite',
                 'authz_groupfile',
                 'ssl']
    $disabled = [ 'auth_basic',
                  'authz_default',
                  'authz_host',
                  'authz_user',
                  'autoindex',
                  'cgi',
                  'authn_file' ]
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


    include zend-framework
    class { 'httpd' :
        http_port => 80,
        https_port => 443
    }
    $enabled = [ 'rewrite',
                 'authz_groupfile',
                 'ssl']
    $disabled = [ 'auth_basic',
                  'authz_default',
                  'authz_host',
                  'authz_user',
                  'autoindex',
                  'cgi',
                  'authn_file' ]
    httpd::module { $enabled:
        ensure => enabled
    }
    httpd::module { $disabled:
        ensure => disabled
    }
}



node "agw-nc10" inherits default-desktop {
}
node "agw-inspiron-1720" inherits default-desktop {
}
node "dev-vm" inherits default-desktop {
}

node "metis.woolie.co.uk" inherits default-server {
}
node "eros.woolie.co.uk" inherits default-server {
}
node "dev.local" inherits default-server {
}
