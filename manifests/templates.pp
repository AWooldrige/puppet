node default {
    include locale
    include default-config
    include python
    include motd
    include ntp
    include sshd
    include sudo
    include vim
    include tmux
    include user-woolie
}

node webnode inherits default {
    class { 'nginx': }
    include loggly
    include nanoc
    include nanoc::compiler
    include aws-tools

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

node raspberry-pi inherits default {
    class { 'nginx': }
    include puppet-auto-update
    include raspi
    include raspi::piface
    include raspi::piuser
    include raspi::vnc
    include raspi::dynamic-dns
    include raspi::information-radiator
    include raspi::home-automation
}
