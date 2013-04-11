class nanoc () {
    package { ['nanoc', 'yuicompressor', 'less']:
        ensure => latest,
        provider => gem
    }
}
