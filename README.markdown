Puppet Configurations
================================
No puppetmaster is needed to apply these configurations, simply:

    puppet apply --modulepath=./modules manifests/sites.pp -vv


Initial System Bootstrap
--------------------------------
Firstly, set the hostname.

    echo agw-nc10.woolie.co.uk > /etc/hostname
    service hostname start

Add the hostname and hostname+domain (e.g. agw-nc10 and agw-nc10.woolie.co.uk) to `/etc/hosts`. Run the following if configuring a new system.

    apt-get install -y puppet git;
    mkdir /etc/puppet/git-distributed;
    cd /etc/puppet/git-distributed;
    git clone http://github.com/AWooldrige/puppet.git;
    cd puppet;
    puppet apply --modulepath=/etc/puppet/git-distributed/puppet/modules /etc/puppet/git-distributed/puppet/manifests/sites.pp -vv;
    passwd woolie;

Populate the file `/root/extlookup/common.csv` with the following:

    mysql/mysql_root_password,<PASS>
    httpd/http_port,80
    httpd/https_port,443
    varnish/port,8080


Conventions
==============================

Files
------------------------------
Each file should be prepended with the following text. Don't forget to change the comment specifier.

    #########################################################################
    ##   This file is controlled by Puppet - changes will be overwritten   ##
    #########################################################################

Notes
==============================

 * Clone this master repo
 * `cd` into submodule directory
 * `git pull origin master`
 * `cd` back to main repo
 * `git st` should show new commits
 * `git commit`
