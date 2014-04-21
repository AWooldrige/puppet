Getting A Box Running
================================
This is a masterless puppet configuration and works solely on puppet apply:

    puppet apply --modulepath=modules manifests/site.pp -vv


Get a Local 'webnode' Running with Vagrant
----------------------------------------
To fix the VirtualBox bug which causes an `ls /vagrant` to hang:

 * Make sure the host machine is running VirtualBox >= 4.3.0
 * The guest additions on the guest machines also need updating to >= 4.3.0.
   This Vagrant plugin automates this. Run this command in the same directory
   as your Vagrantfile: `vagrant plugin install --plugin-source https://rubygems.org --plugin-prerelease vagrant-vbguest`
 * Useful bug references: [why vbguest plugin >= 0.10.0 is needed](https://github.com/dotless-de/vagrant-vbguest/issues/88) and [bug on launchpad](https://bugs.launchpad.net/ubuntu/+bug/1239417)

Then run: `vagrant up webnode` in the project directory. The machine can be
SSH'd into using `vagrant ssh webnode` or on the exposed interface: `ssh
woolie@192.168.42.1`.

Build a 'webnode' AMI using Packer
-----------------------------
From within the project directory: `packer build -var 'aws_access_key=KEY' -var 'aws_secret_key=KEY' packer.json`


Bootstrap a Physical System From Scratch
----------------------------------------

Set the hostname for the machine:

    echo 'machine.woolie.co.uk' > /etc/hostname
    echo '127.0.0.1 machine.woolie.co.uk' >> /etc/hosts
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

Logging
------------------------------
All scripts should log to syslog and to stdout/stderr. This should be managed
within the scripts themselves.


CloudFormation Issues
=======================
* "Currently, Amazon Route 53 supports aliases only for Elastic Load Balancing." -  This means that all DNS entries for S3 (and CloudFronted) sites have to be added manaully to allow A records to be aliased to CloudFront distributions and S3 buckets.
* Price classes can't be set in CloudFront - these are done manually.
* You can't set an S3 bucket up up redirect all requests to another domain - this is done manually.
