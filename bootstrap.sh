#!/usr/bin/env bash
set -eu

function log {
    echo "[$(date --rfc-3339=ns)] ${1}"
}

function install {
    /usr/bin/dpkg -s "$1" && return 0
    for attempt in {1..5}; do
        if ! apt install -y "$1"; then
            log "Could not install ${1} after attempt ${attempt}"
            apt update -y --fix-missing
            sleep 2
        else
            break
        fi
    done
}

if [ -f "/etc/gdpup/.git/HEAD" ]; then
    log "/etc/gdpup/ already exists, not re-cloning"
else
    log 'Updating apt repos'
    apt update -y

    log 'Upgrading apt packages'
    apt upgrade -y

    log 'Installing git and puppet'
    install git
    install puppet

    log 'Installing puppet modules'
    puppet module install puppetlabs-stdlib

    log 'Removing any current puppet code from /etc/gdpup'
    rm -rf /etc/gdpup

    log 'Shallow cloning puppet git repo from master'
    /usr/bin/git clone --depth=1 https://github.com/AWooldrige/puppet.git /etc/gdpup
fi

log 'Running puppet'
puppet apply --modulepath=/etc/gdpup/modules /etc/gdpup/manifests -vv

# https://unix.stackexchange.com/a/465438
case $(passwd --status woolie | awk '{print $2}') in
    NP)  log "No password set for 'woolie', set one:"
        passwd woolie
        ;;
    L)  log "Account 'woolie' is locked, set password"
        passwd woolie
        ;;
    P)  log "Password already set for 'woolie', no need to change." ;;
esac

log 'Finished. Remember to delete temporary user. E.g. userdel -r pi'
