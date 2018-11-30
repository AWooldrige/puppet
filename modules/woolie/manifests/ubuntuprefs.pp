class woolie::ubuntuprefs {
    include woolie

    $uname = $woolie::uname
    $homedir = $woolie::homedir


    exec { 'Set account full name':
        command  => "/usr/bin/chfn -f 'Alistair Wooldrige' ${uname}",
        unless => "/bin/egrep '^${uname}:.*Alistair Wooldrige,' /etc/passwd"
    }

    file { "${homedir}/.ssh/config":
        source  => 'puppet:///modules/woolie/ssh/config',
        owner   => $uname,
        group   => $uname,
        mode    => '0644',
        require => Ssh_authorized_key[$uname]
    }

    file { "${homedir}/.gitconfig":
        source  => 'puppet:///modules/woolie/gitconfig',
        owner   => $uname,
        group   => $uname,
        mode    => '0644',
        require => User[$uname]
    }

    file { "${homedir}/.vim":
        ensure  => directory,
        owner   => $uname,
        group   => $uname,
        mode    => '0755',
        require => [User[$uname], Package['vim-common']]
    } ->
    file { [ "${homedir}/.vim/bundle",
             "${homedir}/.vim/backup",
             "${homedir}/.vim/swap" ]:
        ensure  => directory,
        owner   => $uname,
        group   => $uname,
        mode    => '0755'
    } ->
    file { "${homedir}/.vimrc":
        source  => 'puppet:///modules/woolie/vimrc',
        owner   => $uname,
        group   => $uname,
        mode    => '0644',
        notify  => Exec['vundle-install-plugins']
    }

    # Sometimes the git command will fail, but will still create the vundle
    # directory. This is why the directory is removed as part of the command,
    # and the README.md file is used to determine a successful clone.
    $vndldir = "${homedir}/.vim/bundle/vundle"
    exec { 'install-vundle':
        command     => "rm -rf '${vndldir}' && git clone https://github.com/VundleVim/Vundle.vim.git '${vndldir}'",
        provider    => 'shell',
        logoutput   => 'true',
        user        => $uname,
        tries       => 3,
        creates     => "${vndldir}/README.md",
        require     => [Package['git'], File["${homedir}/.vimrc"]],
        notify      => Exec['vundle-install-plugins']
    }

    # Notes:
    # * Don't use puppet to set the user, this doesn't work.  Must use su so
    #   that # all ENV vars are set.
    # * Vim will moan about input and output not being to a terminal.  Ignore.
    exec { 'vundle-install-plugins':
        command     => "/bin/su -l -c 'vim -c VundleInstall -c quitall' $uname",
        logoutput   => 'true',
        tries       => 3,
        refreshonly => true,
        require     => [Exec["install-vundle"]]
    }
}
