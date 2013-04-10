#!/usr/bin/env bash
#Exit if any unset variables are used, if any command returns an error
set -o nounset
set -o errexit

LOGFILE="/var/log/puppet-git-bootstrap"
function log {
    /bin/echo $(date --rfc-3339=ns)" ${1}"
    /bin/echo $(date --rfc-3339=ns)" ${1}" >> $LOGFILE
}

log 'Starting git distributed puppet bootstrap script'

log ' * Installing git if needed'
/usr/bin/dpkg -s git &> /dev/null || /usr/bin/apt-get install -y -qq git

log ' * Installing puppet if needed'
/usr/bin/dpkg -s puppet &> /dev/null || /usr/bin/apt-get install -y -qq puppet


log ' * Checking if git puppet manifests are checked out'
if [ ! -d /etc/puppet-git/.git ]; then
    log '   ** No manifests found, cloning github repo'
    /usr/bin/git clone http://github.com/AWooldrige/puppet.git /etc/puppet-git

    log '   ** Initialising/Updating submodules'
    /usr/bin/git submodule init /etc/puppet-git
    /usr/bin/git submodule sync /etc/puppet-git
    /usr/bin/git submodule update /etc/puppet-git
fi

log ' * Running puppet apply'
/usr/bin/puppet apply -l $LOGFILE --modulepath=/etc/puppet-git/modules /etc/puppet-git/manifests/sites.pp -vv

log 'Finished'
exit 0
