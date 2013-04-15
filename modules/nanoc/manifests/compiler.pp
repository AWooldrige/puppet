class nanoc::compiler {
    package { ['nanoc', 'yuicompressor', 'less']:
        ensure => latest,
        provider => gem
    }
}
