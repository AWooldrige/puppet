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


Get It Running with Vagrant
--------------------------------
To fix the VirtualBox bug which causes an `ls /vagrant` to hang:

 * Make sure the host machine is running VirtualBox >= 4.3.0
 * The guest additions on the guest machines also need updating to >= 4.3.0.
   This Vagrant plugin automates this. Run this command in the same directory
   as your Vagrantfile: `vagrant plugin install --plugin-source https://rubygems.org --plugin-prerelease vagrant-vbguest`
 * Useful bug references: [why vbguest plugin >= 0.10.0 is needed](https://github.com/dotless-de/vagrant-vbguest/issues/88) and [bug on launchpad](https://bugs.launchpad.net/ubuntu/+bug/1239417)

Then run: `vagrant up` in the project directory. The machine can be SSH'd into
using `vagrant ssh` or on the exposed interface: `ssh woolie@192.168.42.42`.

Get An AMI Built using Packer
--------------------------------
From within the project directory: `packer build -var 'aws_access_key=KEY' -var 'aws_secret_key=KEY' packer.json`

Conventions
==============================

Files
------------------------------
Each file should be prepended with the following text.

    #########################################################################
    ##   This file is controlled by Puppet - changes will be overwritten   ##
    #########################################################################

