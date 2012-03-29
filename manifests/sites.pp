if ! $::osfamily {
  case $::operatingsystem {
    'RedHat', 'Fedora', 'CentOS', 'Scientific', 'SLC', 'Ascendos', 'CloudLinux', 'PSBM', 'OracleLinux', 'OVS', 'OEL': {
      $osfamily = 'RedHat'
    }
    'ubuntu', 'debian': {
      $osfamily = 'Debian'
    }
    'SLES', 'SLED', 'OpenSuSE', 'SuSE': {
      $osfamily = 'Suse'
    }
    'Solaris', 'Nexenta': {
      $osfamily = 'Solaris'
    }
    default: {
      $osfamily = $::operatingsystem
    }
  }
}


$extlookup_datadir = "/root/extlookup/"
$extlookup_precedence = ["nodes/%{hostname}", "common"]

node default {
    $enhancers = [
        'tree',
        'strace',
        'ack-grep',
        'iotop',
        'man-db',
        'makepasswd',
        'curl'
    ]
    $notneeded = [
        'ack'
    ]
    package { $enhancers: ensure => installed }
    package { $notneeded: ensure => purged }

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




#########################################################################
##                             Desktop Nodes                           ##
#########################################################################
node default-desktop inherits default {
    include gvim
    include devtools
    include standard-desktop
}
node "agw-nc10" inherits default-desktop {
}
node "agw-inspiron-1720" inherits default-desktop {
}


#########################################################################
##                           Production Nodes                          ##
#########################################################################
node default-server inherits default {
    include zend-framework
    include woolie-co-uk

    class { 'httpd': }

    # authz_groupfile and authz_host are needed otherwise the Order statement
    # isn't available
    $enabled =  [
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

    httpd::module { $enabled: ensure => enabled }
    httpd::module { $disabled: ensure => disabled }


    class { 'mysql::server':
        config_hash => {
            'root_password' => extlookup('mysql/mysql_root_password')
        }
    }
}
node "hera.woolie.co.uk" inherits default-server {
}
node "metis.woolie.co.uk" inherits default-server {
}
node "devvm.woolie.co.uk" inherits default-server {
}

#########################################################################
##                             Utility Nodes                           ##
#########################################################################
node default-utility-server inherits default {

    class { 'httpd': }

    # authz_groupfile and authz_host are needed otherwise the Order statement
    # isn't available
    $enabled =  [
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

    httpd::module { $enabled: ensure => enabled }
    httpd::module { $disabled: ensure => disabled }
}
node "eros.woolie.co.uk" inherits default-utility-server {
}
