class woolie::ubuntuprefs {
    include woolie

    $uname = $woolie::uname
    $homedir = $woolie::homedir

    exec { 'Set account full name':
        command  => "/usr/bin/chfn -f 'Alistair Wooldrige' ${uname}",
        unless => "/bin/egrep '^${uname}:.*Alistair Wooldrige,' /etc/passwd"
    }


    ###########################################################################
    # SSH
    ###########################################################################
    ssh_authorized_key { $uname:
        ensure  => present,
        user    => $uname,
        type    => 'ssh-ed25519',
        key     => 'AAAAC3NzaC1lZDI1NTE5AAAAIGZexCanfqleYleuE4foaxv/vciAOkukYdecrYqH1OW+',
        require => User[$uname]
    }
    file { "${homedir}/.ssh/config":
        source  => 'puppet:///modules/woolie/dotfiles/ssh_config',
        owner   => $uname,
        group   => $uname,
        mode    => '0644',
        require => Ssh_authorized_key[$uname]
    }


    ###########################################################################
    # GPG
    ###########################################################################
    file { "${homedir}/.gnupg":
        ensure  => directory,
        owner   => $uname,
        group   => $uname,
        mode    => '0755',
        require => [ User[$uname], Package['gnupg'] ]
    } ->
    file { "${homedir}/.gnupg/gpg.conf":
        source  => 'puppet:///modules/woolie/dotfiles/gpg.conf',
        owner   => $uname,
        group   => $uname,
        mode    => '0644',
        require => [ User[$uname], Package['gnupg'] ]
    }


    ###########################################################################
    # Git
    ###########################################################################
    file { "${homedir}/.gitconfig":
        source  => 'puppet:///modules/woolie/dotfiles/gitconfig',
        owner   => $uname,
        group   => $uname,
        mode    => '0644',
        require => User[$uname]
    }


    ###########################################################################
    # VIM
    ###########################################################################
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
        source  => 'puppet:///modules/woolie/dotfiles/vimrc',
        owner   => $uname,
        group   => $uname,
        mode    => '0644',
        notify  => Exec['vundle-install-plugins']
    }
    file { "${homedir}/.gvimrc":
        source  => 'puppet:///modules/woolie/dotfiles/gvimrc',
        owner   => $uname,
        group   => $uname,
        mode    => '0644'
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


    ###########################################################################
    # Bash
    ###########################################################################
    file { "${homedir}/.bash_aliases":
        source  => 'puppet:///modules/woolie/dotfiles/bash_aliases',
        owner   => $uname,
        group   => $uname,
        mode    => '0644',
        require => User[$uname]
    }

    # Ubuntu's default ~/.profile adds ~/bin to the PATH
    file { "${homedir}/bin":
        source  => 'puppet:///modules/woolie/bin',
        owner   => $uname,
        group   => $uname,
        mode    => '0744',
        recurse => true,
        purge   => true,
        force   => true,
        require => User[$uname]
    }


    ###########################################################################
    # Tmux
    ###########################################################################
    file { "${homedir}/.tmux.conf":
        source  => 'puppet:///modules/woolie/dotfiles/tmux.conf',
        owner   => $uname,
        group   => $uname,
        mode    => '0644',
        require => [ User[$uname], Package['tmux'] ]
    }
}
