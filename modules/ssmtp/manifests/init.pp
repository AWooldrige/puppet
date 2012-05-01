class ssmtp {
    $ssmtp_mailhub = extlookup('ssmtp/mailhub')
    $ssmtp_user = extlookup('ssmtp/user')
    $ssmtp_pass = extlookup('ssmtp/pass')

    package { 'ssmtp':
        ensure => installed
    }
    file { '/etc/ssmtp/ssmtp.conf':
        ensure => present,
        owner => 'root',
        group => 'www-data',
        mode => '440',
        require => Package['ssmtp'],
        content => template('ssmtp/ssmtp.conf')
    }
}
