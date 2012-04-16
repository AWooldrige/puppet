class standard-desktop {

/*
    include apt

    apt::source { "chrome":
        components => "stable main",
        uri => "http://dl.google.com/linux/chrome/deb/",
        require => Apt::Key['Quqp'],
        notify => Exec["apt::update-package-index"],
    }

    apt::key {"Quqp":
        ensure => present,
        url => 'https://dl-ssl.google.com/linux/linux_signing_key.pub',
    }

    package { 'google-chrome-unstable' :
        ensure => installed,
        require => Apt::Key['Quqp']
    }
*/
}
