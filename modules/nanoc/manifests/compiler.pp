class nanoc::compiler {
    package { ['nanoc', 'yuicompressor', 'less']:
        ensure => installed,
        provider => gem
    }
    package { ['python-yaml']:
        ensure => installed
    }
}
