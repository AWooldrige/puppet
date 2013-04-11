node default {
    include default-config
    include motd
    include ntp
    include puppet-auto-update
    include sshd
    include sudo
    include vim
    include tmux
    include user-woolie
}

node static-content-server inherits default {
    class { 'httpd':
        http_port => 81,
        webmaster => 'webmaster@woolie.co.uk'
    }
    class { 'httpd::status': }
}

node static-content-and-build-server inherits static-content-server {
    include nanoc
}
