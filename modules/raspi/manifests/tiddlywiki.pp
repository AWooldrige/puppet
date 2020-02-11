class raspi::tiddlywiki {

    exec { 'Check manually added backup symmetric key is present':
       command => '/bin/echo "WARNING: YOU MUST MANUALLY ADD /home/woolie/.backup_key"',
       unless  => '/usr/bin/test -f /home/woolie/.backup_key',
    }


    exec { 'daemon-reload':
        command => '/usr/bin/systemctl daemon-reload',
        refreshonly => true
    }


    exec { 'Install tiddlywiki npm package':
       command => '/usr/bin/npm install -g tiddlywiki',
       unless => '/usr/local/bin/tiddlywiki --version',
       require => Package['nodejs']
    } ->
    file { "/var/www/tw":
        ensure => 'directory',
        owner => 'woolie',
        group => 'www-data',
    } ->
    file { "/etc/systemd/system/tiddlywiki-ww.service":
        source => 'puppet:///modules/raspi/tiddlywiki/tiddlywiki-ww.service',
        owner => 'root',
        group => 'root',
        mode => '0644',
        notify => Exec['daemon-reload']
    } ->
    service { 'tiddlywiki-ww':
        ensure => running,
        enable => true
    }

    file { "/etc/nginx/cg.wooldrige.co.uk.d/tiddlywiki-ww.conf":
        source => 'puppet:///modules/raspi/tiddlywiki/tiddlywiki-ww.conf',
        owner => 'root',
        group => 'root',
        mode => '0644',
        require => File["/etc/nginx/cg.wooldrige.co.uk.d"],
        notify => Service['nginx']
    }


    file { '/usr/local/bin/tiddlywiki-ww-backup':
        source => 'puppet:///modules/raspi/tiddlywiki/tiddlywiki-ww-backup',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        require => Package[[
            'duplicity',
            'python3-boto',
            'python-boto'
        ]]
    } ->
    file { '/usr/local/bin/tiddlywiki-ww-restore':
        source => 'puppet:///modules/raspi/tiddlywiki/tiddlywiki-ww-restore',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    } ->
    cron { 'Backup tiddlywiki-ww daliy':
        ensure  => present,
        command => '/usr/bin/systemd-cat -t "tiddlywiki-ww-backup" /usr/local/bin/tiddlywiki-ww-backup',
        hour     => [3, 15],  # Keep offset from tiddlywiki-ww-gitadd to avoid backing up mid commit
        minute   => 15,
        user    => 'woolie'
    }


    file { '/usr/local/bin/tiddlywiki-ww-gitadd':
        source => 'puppet:///modules/raspi/tiddlywiki/tiddlywiki-ww-gitadd',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        require => Package[[
            'git'
        ]]
    } ->
    cron { 'Commit changes to tiddlywiki-ww regularly':
        ensure  => present,
        command => '/usr/bin/systemd-cat -t "tiddlywiki-ww-gitadd" /usr/local/bin/tiddlywiki-ww-gitadd',
        minute  => [0, 30],
        user    => 'woolie'
    }
}
