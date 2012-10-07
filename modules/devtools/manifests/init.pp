class devtools {

    $buildpackages = [
        'build-essential',
        'dh-make',
        'dpkg-dev',
        'debhelper',
        'devscripts',
        'fakeroot',
        'lintian'
    ]
    package { $buildpackages:
        ensure => installed
    }

    $devpackages = [
        'virtualbox-qt'
    ]
    package { $devpackages:
        ensure => installed
    }

    $phppackages = [
        'php-pear',
        'php-codesniffer'
    ]
    package { $phppackages:
        ensure => installed
    }

    # PHPUnit can't be installed with apt, as it doesn't come
    # with all dependancies
    package { 'phpunit':
        ensure => absent
    }
    exec { 'phpunit-install':
        command => 'pear upgrade pear;pear channel-discover pear.phpunit.de;pear channel-discover components.ez.no;pear channel-discover pear.symfony-project.com;pear install --alldeps phpunit/PHPUnit;',
        path => [
            '/usr/local/bin',
            '/opt/local/bin',
            '/usr/bin',
            '/usr/sbin',
            '/bin',
            '/sbin'],
        require => [ Package['phpunit'],
                     Package['php-pear'] ],
        unless => 'pear list -c phpunit && pear list -c phpunit | grep PHPUnit'
    }

    apt::ppa {'chris-lea':
        ensure => present,
        key    => 'C7917B12',
        ppa    => 'node.js'
    }

    package{['nodejs', 'npm']:
        ensure => installed,
        require => Apt::Ppa['chris-lea']
    }


    package{['less', 'jshint', 'recess', 'uglify-js']:
        provider => npm,
        ensure => installed,
        require => Package['npm']
    }
}
