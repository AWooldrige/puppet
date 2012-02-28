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
    include httpd
}

node default-desktop inherits default {
    include gvim
    include devtools
    include standard-desktop


    include zend-framework
    include httpd
}



node "agw-nc10" inherits default-desktop {
}
node "agw-inspiron-1720" inherits default-desktop {
}


node "metis.woolie.co.uk" inherits default-server {
}
node "eros.woolie.co.uk" inherits default-server {
}
node "dev.local" inherits default-server {
}
