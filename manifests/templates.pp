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
    class { 'nginx': }
    include nanoc
    nanoc::site { 'kempstonnurseries.co.uk':
        ensure => installed
    }
    nanoc::site { 'brignellbookbinders.com':
        ensure => installed
    }
}

node static-content-and-build-server inherits static-content-server {
    include nanoc::compiler
}
