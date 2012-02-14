Puppet Configurations
================================
No puppetmaster is needed to apply these configurations, simply:

    puppet apply --modulepath=./modules manifests/sites.pp -vv


Initial System Bootstrap
--------------------------------
Run the following if configuring a new system.

    apt-get install puppet git;
    mkdir /etc/puppet/git-distributed;
    cd /etc/puppet/git-distributed;
    git clone http://github.com/AWooldrige/puppet.git;
    cd puppet;
    puppet apply --modulepath=/etc/puppet/git-distributed/puppet/modules /etc/puppet/git-distributed/puppet/manifests/sites.pp -vv;


Conventions
==============================

Files
------------------------------
Each file should be prepended with the following text. Don't forget to change the comment specifier.

    ###
    # This file is controlled by Puppet - do not edit
    ###
