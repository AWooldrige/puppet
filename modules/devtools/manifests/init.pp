class devtools {

    package { 'php-pear':
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

    exec { 'phing-install':
        command => 'pear upgrade pear;pear channel-discover pear.phing.info;pear install --alldeps phing/phing;',
        path => [
            '/usr/local/bin',
            '/opt/local/bin',
            '/usr/bin',
            '/usr/sbin',
            '/bin',
            '/sbin'],
        require => Package['php-pear'],
        unless => 'pear list -c phing && pear list -c phing | grep phing'
    }

    package { 'php-codesniffer':
        ensure => installed
    }
}
