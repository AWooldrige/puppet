define base::addusertogroup (
  String[1] $ensure = "exists",
  String[1] $groupname,
  String[1] $username
) {

    if $ensure == 'exists' {
        exec { "Ensure user ${username} added to group ${groupname}":
            unless => "/usr/bin/id -nG ${username} | /bin/grep -qw ${groupname}",
            command => "/sbin/usermod -aG ${groupname} ${username}"
        }
    }
    else {
        warning('Not implemented yet.')
    }
}
