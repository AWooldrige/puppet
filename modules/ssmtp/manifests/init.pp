class ssmtp {
    $ssmtp_mailhub = "smtp.gmail.com:587"
    $ssmtp_user = "noreply@woolie.co.uk"
    $ssmtp_default_sendto = "root-at-${hostname}@woolie.co.uk"
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
