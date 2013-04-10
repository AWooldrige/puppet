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
$extlookup_precedence = ["nodes/${::hostname}", "common"]

$backup_path = "/home/backupincoming/${::hostname}"

Exec { path => '/usr/bin:/bin:/usr/sbin:/sbin' }
Cron { environment => "MAILTO=cron-notify-${hostname}@woolie.co.uk" }

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
node default-wordpress-server inherits default {
    include zend-framework
    include wordpress

    include wp::wooliecouk
    include wp::ompcouk

    class {'httpd':
        http_port => 81
    }
    class {'varnish': }

    include php
    include pear
    include ssmtp

    $mysql_root_password = generate("/root/getpassword", "mysql_root_password")
    class { 'mysql::server':
        config_hash => {
            'root_password' => $mysql_root_password
        }
    }

    class {'diamond':
        graphite_host => 'mon1.woolie.co.uk'
    }
}
node "web1.woolie.co.uk" inherits default-wordpress-server {
    cron {"transfer-incremental-backups":
        ensure => present,
        command => "/usr/bin/chronic /usr/bin/transfer-incremental-backups push",
        user => root,
        hour => 1,
        minute => 0
    }
}
node "devvm.woolie.co.uk" inherits default-wordpress-server {
    cron {"transfer-incremental-backups":
        ensure => absent
    }
    include devtools
}

#########################################################################
##                             Utility Nodes                           ##
#########################################################################
node default-monitoring-server inherits default {
    include user-backupincoming
    include httpd
    include graphite

    cron {"transfer-incremental-backups":
        ensure => absent
    }

    class {'diamond':
        graphite_host => '127.0.0.1'
    }
}
node "mon1.woolie.co.uk" inherits default-monitoring-server {
}
