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
    class { 'httpd::purge': }
    include nginx
}

node static-content-and-build-server inherits static-content-server {
    include nanoc
}
