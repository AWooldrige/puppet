#!/bin/bash

######################################
# BEGIN CONFIGURATION

extlookupcsvfile='/root/extlookup/common.csv'

fields=( "httpd/http_port,<port for apache to list on - e.g. 81>"
         "httpd/https_port,<port for SSL apache to listen on - e.g. 443>"
         "varnish/httpd_http_host,<host to retrieve content - e.g. 127.0.0.1>"
         "varnish/port,<port for varnish to listen on - e.g. 80>"
         "backup/path,<remote path for backups - e.g. backup8::/var/bkps or /var/bkps>"
         "ssmtp/mailhub,<SMTP mail address - e.g. smtp.gmail.com:587>"
         "ssmtp/user,<SMTP user name - e.g. noreply@woolie.co.uk>"
         "ssmtp/pass,<SMTP password>" )

# END CONFIGURATION
######################################

echo 'Git Distributed Puppet Bootstrap Script'
echo '---------------------------------------'

echo ' * Checking if git is installed'
dpkg -s git &> /dev/null || apt-get install -y -qq git || exit $?

echo ' * Checking if puppet is installed'
dpkg -s puppet &> /dev/null || apt-get install -y -qq puppet || exit $?

echo ' * Checking if the extlookup csv file is present'
[ -d /root/extlookup ] || mkdir -p /root/extlookup
[ -f $extlookupcsvfile ] || touch $extlookupcsvfile

echo ' * Checking all parameters are present within extlookup csv file'
edit=0
for i in "${fields[@]}"
do
    key=`echo $i | tr "," "\n" | head -n 1`

    if ! grep $key $extlookupcsvfile > /dev/null; then
        echo "${i}" >> $extlookupcsvfile
        edit=1
    fi
done

if [ $edit == 1 ]; then
    echo '  ** Parameters missing in extlookup csv file, need to edit'
    vim $extlookupcsvfile
fi


echo ' * Checking if github puppet manifests are checked out'
if [ ! -d /etc/puppet/git-distributed/puppet/.git ]; then
    echo '   ** No manifests found, cloning github repo'
    mkdir -p /etc/puppet/git-distributed
    cd /etc/puppet/git-distributed
    git clone http://github.com/AWooldrige/puppet.git || exit $?

    echo '   ** Updating submodules'
    cd /etc/puppet/git-distributed/puppet
    git submodule init || exit $?
    git submodule update || exit $?


    echo '   ** Adding getpassword'
    dpkg -s pwgen &> /dev/null || apt-get install -y -qq pwgen || exit $?
    curl https://raw.github.com/AWooldrige/puppet/master/modules/default-config/files/getpassword > /root/getpassword
    chmod 500 /root/getpassword

    echo '   ** Running puppet'
    puppet apply --modulepath=modules ./manifests/sites.pp || exit $?

    echo '   ** Set password for woolie'
    passwd woolie || exit $?
fi

echo 'Finished'
exit 0
