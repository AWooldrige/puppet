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

    bash <(curl -s https://raw.github.com/AWooldrige/puppet/gen2/bootstrap.sh gen2)



Conventions
==============================

Files
------------------------------
Each file should be prepended with the following text.

    #########################################################################
    ##   This file is controlled by Puppet - changes will be overwritten   ##
    #########################################################################

