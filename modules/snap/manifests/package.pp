define snap::package (
  String[1] $ensure = "installed",
  String[1] $packagename = $title
) {

    include snap

    if $ensure == 'installed' {
        exec { "install_snap_${packagename}":
            command => "snap install '${packagename}'",
            unless => "snap list | egrep '^${packagename}'",
            provider => "shell",
            require => [ Package["snapd"] ]
        }
    }
    else {
        warning('Not implemented yet.')
    }
}
