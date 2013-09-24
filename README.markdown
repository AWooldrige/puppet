Puppet Configuration
================================
This is a masterless puppet configuration and works solely on puppet apply:

    puppet apply --modulepath=modules manifests/site.pp -vv


Initial System Bootstrap
--------------------------------

Set the hostname for the machine:

    echo 'cloud-local' > /etc/hostname
    echo '127.0.0.1 cloud-local' >> /etc/hosts
    service hostname start

Run the bootstrap.sh script:

    F=/tmp/boostrap.sh && rm -f $F && wget --tries=10 https://raw.github.com/AWooldrige/puppet/master/bootstrap.sh -O $F && chmod +x $F && sudo $F master && rm -f $F



Conventions
==============================

Files
------------------------------
Each file should be prepended with the following text.

    #########################################################################
    ##   This file is controlled by Puppet - changes will be overwritten   ##
    #########################################################################

