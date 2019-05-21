class raspi::noscreenblanking {

    $asfile = '/etc/xdg/lxsession/LXDE-pi/autostart'

    file_line { 'No screen blank':
        path => $asfile,
        line => '@xset s noblank',
    }
    file_line { 'No screen blank p2':
        path => $asfile,
        line => '@xset s off',
    }
    file_line { 'No screen blank p3':
        path => $asfile,
        line => '@xset -dpms',
    }

}
