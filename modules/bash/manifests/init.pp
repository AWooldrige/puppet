class bash {
    file { "/root/.bashrc":
        owner   => 'root',
        group   => 'root',
        mode    => '644',
        content => template("bash/bashrc"),
    }
}
