#!/usr/bin/env bash
set -eu

# Script principle:
# 1) Idempotent. It should be possible to run this script multiple times.

function log {
    echo "[$(date --rfc-3339=ns)] ${1}"
}

function install {
    dpkg -s "$1" && return 0
    for attempt in {1..5}; do
        if ! apt install -y "$1"; then
            echo "Could not install ${1} after attempt ${attempt}"
            apt update -y --fix-missing
            sleep 2
        else
            break
        fi
    done
}

function initialise_securepuppet {
    SP_DIR="/etc/securepuppet/modules/secure/manifests"
    if [ ! -d "$SP_DIR" ]; then
        log "Creating secure puppet module directory at: $SP_DIR"
        mkdir -p "$SP_DIR"
    fi

    SP_MFST="${SP_DIR}/init.pp"
    if ! grep 'class secure' "$SP_MFST" 1> /dev/null 2> /dev/null; then
        log "Creating secure puppet manifest file: $SP_MFST"
        echo 'class secure {}' > "$SP_MFST"
    fi
    chmod -R 600 /etc/securepuppet
}

if [ -f "/root/puppet/.git/HEAD" ]; then
    log "/root/puppet/ already exists, not re-cloning"
else
    log 'Updating apt repos'
    apt update -y

    log 'Upgrading apt packages'
    apt upgrade -y

    log 'Installing git and puppet'
    install git
    install puppet

    log 'Installing puppet modules'
    puppet module install puppetlabs-cron_core
    puppet module install puppetlabs-sshkeys_core
    puppet module install puppetlabs-stdlib
    puppet module install puppetlabs-apt

    log 'Cloning puppet confs repo to /root/puppet'
    /usr/bin/git clone --depth=1 https://github.com/AWooldrige/puppet.git /root/puppet

    log 'Installing puppet modules'
    initialise_securepuppet
fi

log 'Complete, now:'
log '  1) Optional: populate /etc/securepuppet'
log '  2) Optional: modify local /root/puppet'
log '  3) cd /root/puppet && ./apply.sh'
