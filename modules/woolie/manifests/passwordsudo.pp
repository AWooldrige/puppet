class woolie::passwordsudo {

    base::addusertogroup { 'woolie in passwordsudo':
        username  => 'woolie',
        groupname => 'passwordsudo',
        require   => [User['woolie'], Group['passwordsudo']]
    }
}
