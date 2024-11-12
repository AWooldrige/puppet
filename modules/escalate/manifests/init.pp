class escalate {

    file { '/etc/google_chat_webhook_url':
        owner  => 'root',
        group  => 'root',
        mode   => '0600',
        content => $secure::google_chat_webhook_url
    }

    file { '/usr/local/sbin/escalate':
        source => 'puppet:///modules/escalate/escalate',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        require => [
            File['/etc/google_chat_webhook_url'],
            Package['python3-click'],
            Package['python3-requests']
        ]
    }
}
