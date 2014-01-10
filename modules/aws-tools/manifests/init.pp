class aws-tools {
    file { "/usr/bin/associate-eip-with-self":
        source  => "puppet:///modules/aws-tools/associate-eip-with-self",
        owner   => "root",
        group   => "root",
        mode    => "0755",
        require => [
            Package["python-boto"],
            File["/usr/lib/python2.7/dist-packages/woolielibs"]
        ]
    }

    $cmd = "/usr/bin/chronic /usr/bin/associate-eip-with-self"
    cron {"associate-eip-with-self-on-reboot":
        ensure  => present,
        command => $cmd,
        user    => root,
        special => "reboot",
        require => File["/usr/bin/associate-eip-with-self"]
    }
}
