define pipx::package (
  String[1] $ensure = "installed",
  String[1] $packagename = $title
) {

    include pipx

    if $ensure == 'installed' {
        exec { "install ${packagename} from pipx":
            command => "/usr/bin/pipx install '${packagename}'",
            unless => "/usr/bin/pipx list --short | /usr/bin/egrep '^${packagename} '",
            provider => "shell"
        }
    }
    elsif $ensure == 'absent' {
        exec { "remove ${packagename} from pipx":
            command => "/usr/bin/pipx uninstall '${packagename}'",
            onlyif => "/usr/bin/pipx list --short | /usr/bin/egrep '^${packagename} '",
            provider => "shell"
        }
    }
    else {
        warning('Not implemented yet.')
    }
}
