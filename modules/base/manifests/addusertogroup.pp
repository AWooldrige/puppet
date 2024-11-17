define base::addusertogroup (
  String[1] $ensure = "exists",
  String[1] $groupname,
  String[1] $username
) {

    if $ensure == 'exists' {
        exec { "Ensure user ${username} added to group ${groupname}":
            unless => "/bin/grep -q '${groupname}\\S*${username}' /etc/group",
            command => "/sbin/usermod -aG ${groupname} ${username}"
        }
    }
    else {
        warning('Not implemented yet.')
    }
}
