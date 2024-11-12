class raspi::tiddlywiki {

    exec { 'daemon-reload':
        command => '/usr/bin/systemctl daemon-reload',
        refreshonly => true
    }

    exec { 'Install tiddlywiki npm package':
       command => '/usr/bin/npm install -g tiddlywiki',
       creates => '/usr/local/bin/tiddlywiki',
       require => Package['npm']
    } ->
    group { 'tiddlywiki':
        ensure => 'present',
        gid => 21001
    } ->
    user { 'tiddlywiki':
        ensure => 'present',
        comment => 'TiddlyWiki local server',
        uid => 19001,
        gid => 'tiddlywiki'
    } ->
    file { ["/var/lib/tiddlywiki", "/var/lib/tiddlywiki/ww"]:
        ensure => 'directory',
        owner => 'tiddlywiki',
        group => 'tiddlywiki'
    } ->
    file { "/etc/systemd/system/tiddlywiki-ww.service":
        source => 'puppet:///modules/raspi/tiddlywiki/tiddlywiki-ww.service',
        owner => 'root',
        group => 'root',
        mode => '0644',
        notify => [
            Exec['daemon-reload'],
            Service['tiddlywiki-ww']
        ]
    } ->
    service { 'tiddlywiki-ww':
        ensure => running,
        enable => true
    }

    file { "/etc/nginx/h.wooldrige.co.uk.d/tiddlywiki-ww.conf":
        source => 'puppet:///modules/raspi/tiddlywiki/tiddlywiki-ww.conf',
        owner => 'root',
        group => 'root',
        mode => '0644',
        require => File["/etc/nginx/h.wooldrige.co.uk.d"],
        notify => Service['nginx']
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
        user    => 'tiddlywiki',
        require => User['tiddlywiki']
    }

    file { '/usr/local/sbin/backup-tiddlywiki-ww':
        source => 'puppet:///modules/raspi/tiddlywiki/backup-tiddlywiki-ww',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }
    cron { 'Backup tiddlywiki-ww daliy':
        ensure  => present,
        command => '/usr/bin/systemd-cat -t "backup-tiddlywiki-ww" /usr/local/sbin/backup-tiddlywiki-ww',
        # Keep offset from tiddlywiki-ww-gitadd to avoid backing up mid commit
        # Keep offset from gdpup as it will start the systemd service again mid backup
        hour => [23],
        minute => 51,
        require => [
            File['/usr/local/sbin/backup-tiddlywiki-ww'],
            Service['tiddlywiki-ww']
        ]
    }
}
