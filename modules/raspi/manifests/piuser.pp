class raspi::piuser {
    user { 'pi':
        ensure     => present,
        comment    => 'Default user with Raspian',
        gid        => 'pi',
        groups     => ['passwordsudo', 'lp'],
        shell      => '/bin/bash',
        home       => '/home/pi',
        managehome => true,
        require    => Group['passwordsudo']
    }
}
