class ddns::remove {
    file { '/usr/local/bin/ddns':
        ensure  => absent
    }
    cron { 'Check Dynamic DNS entry at regular intervals':
        ensure  => absent,
        user    => 'woolie'
    }
    cron { 'Check Dynamic DNS entry at boot':
        ensure  => absent,
        user    => 'woolie'
    }
}
