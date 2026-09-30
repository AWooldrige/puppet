# Raspberry Pi Touch Display 2 (7", 720x1280 native portrait, DSI).
class raspi::touchdisplay {

    group { 'paneltouch':
        ensure => 'present',
        gid    => 19006
    }

    file { '/usr/local/sbin/panel-backlight-init':
        source => 'puppet:///modules/raspi/touchdisplay/panel-backlight-init',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    } ->
    file { '/etc/systemd/system/panel-backlight-init.service':
        source => 'puppet:///modules/raspi/touchdisplay/panel-backlight-init.service',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify => Exec['daemon-reload']
    } ->
    file { '/etc/udev/rules.d/99-panel-backlight.rules':
        source  => 'puppet:///modules/raspi/touchdisplay/99-panel-backlight.rules',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Group['paneltouch'],
        notify  => Exec['udev-reload']
    }

    # systemd-backlight@ restores the brightness saved at shutdown, which races the
    # udev rule and can leave the panel off. 
    file { '/etc/systemd/system/systemd-backlight@.service':
        ensure => 'link',
        target => '/dev/null',
        notify => Exec['daemon-reload']
    }
}
