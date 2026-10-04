class workstation::vocalinux {
    include dconf
    include woolie

    $version = '0.17.0'
    $releases = {
        'amd64' => ['x86_64', '13f7d9d765b359d722570255654be04fcbf1e08014924a70a769bc0da375a8b9'],
        'arm64' => ['aarch64', 'fe9879d09daed53dba21ff0d8d60bc5b4121cb76250a559d0ad1d978d0c60f23'],
    }

    unless $facts['os']['architecture'] in $releases {
        fail("workstation::vocalinux has no pinned bundle for ${facts['os']['architecture']}")
    }
    [$arch, $checksum] = $releases[$facts['os']['architecture']]
    $bundle = "/var/cache/packages/Vocalinux-${version}-${arch}.flatpak"

    flatpak::package { 'org.gnome.Platform//50':
        ensure => 'installed'
    }

    exec { "Download and verify Vocalinux ${version} for ${arch}":
        command  => "curl -fsSL -o ${bundle}.part https://github.com/VocaHQ/vocalinux/releases/download/v${version}/Vocalinux-${version}-${arch}.flatpak && echo '${checksum}  ${bundle}.part' | sha256sum -c - && mv ${bundle}.part ${bundle}",
        provider => 'shell',
        creates  => $bundle,
        timeout  => 600,
        require  => [
            File['/var/cache/packages'],
            Package['curl']
        ]
    } ->
    exec { "Install Vocalinux ${version}":
        command  => "flatpak install --system --noninteractive --reinstall ${bundle}",
        unless   => "flatpak info com.vocalinux.Vocalinux | grep -q 'Version: ${version}'",
        provider => 'shell',
        timeout  => 600,
        require  => Flatpak::Package['org.gnome.Platform//50']
    } ->
    exec { 'Sandbox Vocalinux: no raw devices, no X11':
        command  => 'flatpak override --system com.vocalinux.Vocalinux --nodevice=all --nosocket=x11',
        unless   => "flatpak override --system --show com.vocalinux.Vocalinux | grep -q '!all' && flatpak override --system --show com.vocalinux.Vocalinux | grep -q '!x11'",
        provider => 'shell'
    }

    file { '/etc/dconf/db/local.d/20-vocalinux':
        ensure => 'absent',
        notify => Exec['dconf-update']
    }

    file { '/usr/local/bin/vocalinux-initial-prompt':
        source => 'puppet:///modules/workstation/vocalinux-initial-prompt',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }

    file { "${woolie::homedir}/.config/vocalinux-initial-prompt":
        ensure    => 'file',
        owner     => $woolie::uname,
        group     => $woolie::uname,
        mode      => '0600',
        show_diff => false,
        backup    => false,
        content   => $secure::vocalinux_initial_prompt,
        require   => File["${woolie::homedir}/.config"]
    }

    $prompt_args = "${woolie::homedir}/.config/vocalinux-initial-prompt ${woolie::homedir}/.var/app/com.vocalinux.Vocalinux/config/vocalinux/config.json"
    exec { 'Set the Vocalinux initial prompt':
        command => "/usr/local/bin/vocalinux-initial-prompt ${prompt_args}",
        unless  => "/usr/local/bin/vocalinux-initial-prompt ${prompt_args} --check",
        user    => $woolie::uname,
        require => [
            File['/usr/local/bin/vocalinux-initial-prompt'],
            File["${woolie::homedir}/.config/vocalinux-initial-prompt"],
            Exec["Install Vocalinux ${version}"]
        ]
    }
}
