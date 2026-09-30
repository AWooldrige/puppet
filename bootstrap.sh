#!/usr/bin/env bash
# Installs puppet, clones this repo and applies it. Safe to re-run.
# Secrets must already be in place: run provision.py against the host first.
set -eu

# Wait for the apt lock rather than failing on it. On a freshly installed box
# unattended-upgrades can take a long time.
APT="apt -o DPkg::Lock::Timeout=1800"

function log {
    echo "[$(date --rfc-3339=ns)] ${1}"
}

function install {
    dpkg -s "$1" && return 0
    for attempt in {1..5}; do
        if ! $APT install -y "$1"; then
            echo "Could not install ${1} after attempt ${attempt}"
            $APT update -y --fix-missing
            sleep 2
        else
            break
        fi
    done
}

if [ ! -f "/root/puppet/.git/HEAD" ]; then
    log 'Updating apt repos'
    $APT update -y

    log 'Upgrading apt packages'
    # https://askubuntu.com/a/1431746
    NEEDRESTART_MODE=a $APT upgrade -y

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

cd /root/puppet
[ -n "${SKIP_APPLY:-}" ] || exec ./apply.sh
