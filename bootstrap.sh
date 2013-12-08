#!/usr/bin/env bash
#Exit if any unset variables are used, if any command returns an error
set -o nounset
set -o errexit

function log {
    /bin/echo $(date --rfc-3339=ns)" ${1}"
}

usage="Usage: $0 [branch]"

if /usr/bin/[ "$#" -gt 1 ]; then
    /bin/echo $usage
    exit 1
fi
log 'Starting git distributed puppet bootstrap script'

log ' * Updating apt repos'
/usr/bin/apt-get update -y

log ' * Upgrading apt packages'
/usr/bin/apt-get upgrade -y

log ' * Installing git and puppet if needed'
/usr/bin/dpkg -s git &> /dev/null || /usr/bin/apt-get install -y git
/usr/bin/dpkg -s puppet &> /dev/null || /usr/bin/apt-get install -y puppet

log ' * Installing ruby-hiera until dependency fixed in #1242363'
/usr/bin/dpkg -s ruby-hiera &> /dev/null || /usr/bin/apt-get install -y ruby-hiera

log ' * Removing any currently manifests'
rm -rf /etc/puppet-git

if [ -d "/vagrant" ]; then
    log "   ** We're on a Vagrant box! Copying over manifests/modules. If this command hangs, see the README"
    cp -R /vagrant /etc/puppet-git
else
    log '   ** No manifests found, cloning github repo from master'
    /usr/bin/git clone http://github.com/AWooldrige/puppet.git /etc/puppet-git
fi

log '   ** Initialising/Updating submodules'
cd /etc/puppet-git
/usr/bin/git submodule init
/usr/bin/git submodule sync
/usr/bin/git submodule update
cd -

log ' * Running puppet apply'
/usr/bin/puppet apply --modulepath=/etc/puppet-git/modules /etc/puppet-git/manifests/site.pp -vv

log 'Finished!'
exit 0
