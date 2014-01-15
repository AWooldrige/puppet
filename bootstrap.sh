#!/usr/bin/env bash
#Exit if any unset variables are used, if any command returns an error
set -o nounset
set -o errexit

function log {
    echo $(date --rfc-3339=ns)" ${1}"
}

function install {
    if ! /usr/bin/dpkg -s $1 &> /dev/null; then
        log "Installing ${1} package"
        for attempt in {1..5}; do
            if ! apt-get install -y $1; then
                log "Could not install ${1} after attempt ${attempt}"
                apt-get update -y --fix-missing
                sleep 2
            else
                break
            fi
        done
    else
        log "${1} package already installed"
    fi
}

usage="Usage: $0 [branch]"

if /usr/bin/[ "$#" -gt 1 ]; then
    /bin/echo $usage
    exit 1
fi
log 'Starting git distributed puppet bootstrap script'

log ' * Updating apt repos'
apt-get update -y

log ' * Upgrading apt packages'
apt-get upgrade -y

log ' * Installing git and puppet if needed'
install git
install puppet

log ' * Installing ruby-hiera until dependency fixed in #1242363'
install ruby-hiera

log ' * Removing any currently manifests'
rm -rf /etc/puppet-git

if [ -d "/vagrant" ]; then
    log " * We're on a Vagrant box! Copying over manifests/modules. If this command hangs, see the README"
    cp -R /vagrant /etc/puppet-git
else
    log ' * Shallow cloning puppet github repo from master'
    /usr/bin/git clone --depth=1 http://github.com/AWooldrige/puppet.git /etc/puppet-git
fi

log ' * Initialising/Updating git submodules'
cd /etc/puppet-git
git submodule init
git submodule sync
git submodule update
cd -

log ' * Running puppet apply'
puppet apply --modulepath=/etc/puppet-git/modules /etc/puppet-git/manifests/site.pp -vv

log 'Finished!'
exit 0
