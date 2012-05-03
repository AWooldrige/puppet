Puppet Configurations
================================
No puppetmaster is needed to apply these configurations, simply:

    puppet apply --modulepath=./modules manifests/sites.pp -vv


Initial System Bootstrap
--------------------------------

    echo agw-nc10.woolie.co.uk > /etc/hostname
    service hostname start

Add the hostname and hostname+domain (e.g. agw-nc10 and agw-nc10.woolie.co.uk) to `/etc/hosts`.

Run the puppet-bootstrap.sh script which installs git and puppet, clones this repository and runs puppet with those manifests

    bash <(curl -s https://raw.github.com/AWooldrige/puppet/master/puppet-bootstrap.sh)



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
