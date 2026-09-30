class workstation::sops {
    include woolie

    # sops decrypts the fleet secret manifest. It is not in the Ubuntu archive, so
    # it comes from the project's own .deb, pinned by version and sha256.
    #
    # The obvious way to write this - `file` with an https `source` plus
    # `checksum`/`checksum_value` - does NOT work: with checksum_value set, Puppet
    # silently does nothing at all.
    $version = '3.13.3'
    $architecture = $facts['os']['architecture']
    $checksums = {
        'amd64' => '927c45f2ccb5b1c9acb1e80c7befaea0672c721fd3f222697a51e0a7081e3f3b',
        'arm64' => '21cf1ee8860bb9c2a0b09ac97901b41ca9f95734f3402ea358e31e296e6be823'
    }

    unless $architecture in $checksums {
        fail("workstation::sops has no pinned sops checksum for ${architecture}")
    }

    $package = "/var/cache/packages/sops_${version}_${architecture}.deb"

    exec { "Download and verify sops ${version} for ${architecture}":
        command  => "curl -fsSL -o ${package}.part https://github.com/getsops/sops/releases/download/v${version}/sops_${version}_${architecture}.deb && echo '${checksums[$architecture]}  ${package}.part' | sha256sum -c - && mv ${package}.part ${package}",
        provider => 'shell',
        creates  => $package,
        timeout  => 300,
        require  => [
            File['/var/cache/packages'],
            Package['curl']
        ]
    } ->
    package { 'sops':
        ensure => installed,
        source => $package
    }

    # The key is copied in by hand
    file { "${woolie::homedir}/.config":
        ensure  => 'directory',
        owner   => $woolie::uname,
        group   => $woolie::uname,
        require => User[$woolie::uname]
    } ->
    file { "${woolie::homedir}/.config/sops":
        ensure => 'directory',
        owner  => $woolie::uname,
        group  => $woolie::uname,
        mode   => '0700'
    } ->
    file { "${woolie::homedir}/.config/sops/age":
        ensure => 'directory',
        owner  => $woolie::uname,
        group  => $woolie::uname,
        mode   => '0700'
    } ->
    file { "${woolie::homedir}/.config/sops/age/keys.txt":
        ensure  => 'file',
        replace => false,
        owner   => $woolie::uname,
        group   => $woolie::uname,
        mode    => '0600'
    }
}
