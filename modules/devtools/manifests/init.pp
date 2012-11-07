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

    package { 'php-codesniffer':
        ensure => installed
    }

    # PHPUnit can't be installed with apt, as it doesn't come
    # with all dependancies
    package { 'phpunit':
        ensure => absent
    }
    exec { 'phpunit-install':
        command => 'pear upgrade pear;pear channel-discover pear.phpunit.de;pear channel-discover components.ez.no;pear channel-discover pear.symfony-project.com;pear update-channels;pear install --alldeps phpunit/PHPUnit;',
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

    include nodejs

    package{['less', 'jshint', 'recess', 'uglify-js']:
        provider => npm,
        ensure => installed
    }
}
