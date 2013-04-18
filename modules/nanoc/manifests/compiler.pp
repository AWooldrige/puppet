class nanoc::compiler {
    package { 'ruby-dev':
        ensure => installed
    }
    package { ['nanoc', 'rainpress', 'less', 'therubyracer']:
        ensure   => installed,
        provider => gem,
        require  => Package['ruby-dev', 'make', 'g++']
    }
    package { ['python-yaml']:
        ensure => installed
    }
    file { '/usr/bin/nh':
        source => 'puppet:///modules/nanoc/nh',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }
    file { '/usr/bin/nanoc-site-downloader':
        source => 'puppet:///modules/nanoc/nanoc-site-downloader',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }
}
