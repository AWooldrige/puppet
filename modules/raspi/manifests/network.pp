class raspi::network {

    # Whatever interfaces the host has an address for: wifi only, ethernet only, or
    # both at once. Ethernet gets the lower route metric.
    $ethernets = $secure::addresses.filter |$interface, $address| {
        $interface !~ /^(wl|wifi)/
    }
    $wifis = $secure::addresses.filter |$interface, $address| {
        $interface =~ /^(wl|wifi)/
    }

    file { '/etc/cloud/cloud.cfg.d/99-disable-network.cfg':
        ensure  => 'present',
        content => 'network: {config: disabled}',
        owner   => 'root',
        group   => 'root',
        mode    => '0644'
    } ->
    # Netplan merges in filename order, so cloud-init's 50- file would override the
    # 49- one below. Disabling cloud-init networking stops it being regenerated but
    # does not remove what the first boot left behind.
    file { '/etc/netplan/50-cloud-init.yaml':
        ensure => 'absent'
    } ->
    # Deliberately no netplan apply. This is the only route on and off a wifi-only
    # Pi, so a wrong config here would strand the host.
    file { '/etc/netplan/49-netplan-woolie.yaml':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0600',
        content => epp(
            'raspi/49-netplan-woolie.yaml.epp',
            {
                'ethernets' => $ethernets,
                'wifis' => $wifis,
                'gateway' => $secure::gateway,
                'nameservers' => $secure::nameservers,
                'regulatory_domain' => $secure::regulatory_domain,
                'wifi_ssid' => $secure::wifi_ssid,
                'wifi_password' => $secure::wifi_password
            }
        )
    }
}
