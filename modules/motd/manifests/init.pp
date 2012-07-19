class motd {
    file { "/etc/issue":
        owner   => 'root',
        group   => 'root',
        mode    => '644',
        content => template("motd/issue"),
    }
    file { "/etc/issue.net":
        owner   => 'root',
        group   => 'root',
        mode    => '644',
        content => template("motd/issue"),
    }

    # Disable the current MOTD scripts
    file { [
        "/etc/update-motd.d/00-header",
        "/etc/update-motd.d/10-help-text",
        "/usr/share/landscape/landscape-sysinfo.wrapper",
        "/etc/update-motd.d/90-updates-available",
        "/etc/update-motd.d/91-release-upgrade",
        "/etc/update-motd.d/98-fsck-at-reboot",
        "/etc/update-motd.d/98-reboot-required",
        "/etc/update-motd.d/99-footer"
        ]:
        owner   => 'root',
        group   => 'root',
        mode    => '644'
    }

    file { "/etc/update-motd.d/00-custom-motd":
        owner   => 'root',
        group   => 'root',
        mode    => '744',
        content => template("motd/motd")
    }
}
