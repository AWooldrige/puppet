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

Exec { path => '/usr/bin:/bin:/usr/sbin:/sbin' }

node default {
    include default-config
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
    include wordpress
    include woolie-co-uk
    include onmyplate-co-uk

    class { 'httpd': }
    include php
    include ssmtp
    include varnish

    # authz_groupfile and authz_host are needed otherwise the Order statement
    # isn't available
    $enabled =  [
        'rewrite',
        'authz_groupfile',
        'authz_host',
        'ssl',
        'alias',
        'headers'
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


    $mysql_root_password = generate("/root/getpassword", "mysql_root_password")

    class { 'mysql::server':
        config_hash => {
            'root_password' => $mysql_root_password
        }
    }
}
node "hera.woolie.co.uk" inherits default-server {
}
node "metis.woolie.co.uk" inherits default-server {
}
node "devvm.woolie.co.uk" inherits default-server {
    include devtools
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
