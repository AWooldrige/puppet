class python {
    package { 'python':
        ensure => installed
    }
    file { '/usr/lib/python2.7/dist-packages/woolielibs':
        source  => 'puppet:///modules/python/woolielibs',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        recurse => true,
        purge   => true,
        force   => true,
        require => Package['python']
    }
}
