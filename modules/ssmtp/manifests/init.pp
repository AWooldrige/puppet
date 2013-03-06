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
    file { "/usr/share/diamond/user_scripts/ssmtp_metrics":
        source => 'puppet:///modules/ssmtp/ssmtp_metrics',
        owner => "root",
        group => "root",
        mode  => '744',
        require => Package["diamond"],
        notify  => Service["diamond"]
    }
}
