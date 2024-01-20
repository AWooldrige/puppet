define flatpak::package (
  String[1] $ensure = "installed",
  String[1] $packagename = $title,
  String[1] $repo = "flathub"
) {

    include flatpak

    if $ensure == 'installed' {
        exec { "install_flatpak_from_${repo}_${packagename}":
            command => "flatpak install '${repo}' '${packagename}' --noninteractive",
            unless => "flatpak info '${packagename}'",
            provider => "shell",
            require => [ Exec["${repo}_repo"] ]
        }
    }
    else {
        warning('Not implemented yet.')
    }
}
