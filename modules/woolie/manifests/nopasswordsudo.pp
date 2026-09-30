class woolie::nopasswordsudo {

    # For non workstation machines: servers and Pis
    base::addusertogroup { 'woolie in nopasswordsudo':
        username  => 'woolie',
        groupname => 'nopasswordsudo',
        require   => [User['woolie'], Group['nopasswordsudo']]
    }

    # sudoers takes the last matching rule and passwordsudo is listed after nopasswordsudo, so it would win.
    exec { 'Remove woolie from passwordsudo':
        command => '/usr/bin/gpasswd -d woolie passwordsudo',
        onlyif  => '/usr/bin/id -nG woolie | /bin/grep -qw passwordsudo',
        require => Base::Addusertogroup['woolie in nopasswordsudo']
    }
}
