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

node static-content-and-build-server inherits default {
    class { 'nginx': }
    include loggly
    include nanoc
    include nanoc::compiler

    nanoc::site { 'brignellbookbinders.com':
        ensure => installed,
        repo   => 'https://github.com/AWooldrige/brignellbookbinders.com.git'
    }
    nanoc::site { 'onmyplate.co.uk':
        ensure => installed,
        repo   => 'https://github.com/AWooldrige/onmyplate.co.uk.git'
    }
    nanoc::site { 'woolie.co.uk':
        ensure => installed,
        repo   => 'https://github.com/AWooldrige/woolie.co.uk.git'
    }
    nanoc::site { 'kempstonnurseries.co.uk':
        ensure => installed,
        repo   => 'https://github.com/AWooldrige/kempstonnurseries.co.uk.git'
    }
}
