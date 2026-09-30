class woolie::managedpassword {
    include woolie

    User <| title == 'woolie' |> {
        password => $secure::woolie_password_hash
    }
}
