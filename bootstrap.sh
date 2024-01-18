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

if [ ! -d "/etc/securepuppet" ]; then
    log "Copy in secure puppet module to /etc/securepuppet before continuing."
    exit 1
fi

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
fi

log 'Complete. Enter /root/puppet, make changes if needed, then run ./apply.sh.'
