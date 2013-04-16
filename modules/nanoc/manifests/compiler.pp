class nanoc::compiler {
    package { ['nanoc', 'yuicompressor', 'less']:
        ensure => installed,
        provider => gem
    }
}
