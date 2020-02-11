Bootstrapping a system from scratch
============================================

1) Install OS
-------------
 1. If boostrapping a physical machine (not a VM), enable full drive
    encryption. This reduces risk from hardware theft. There's no point
    encrypting a VM drive, the host has full access anyway.
 2. Do not create a user named `woolie` as part of setup, instead create a
    temporary user which will only be used to run puppet and will be removed
    after. Puppet needs to create the `woolie` user to keep UIDs/GIDs in sync.
 3. Set hostname if asked, following scheme of {model}{increment}.


2) Run puppet
-------------
Set the hostname for the machine if not set during OS install, following the
scheme of {model}{increment}:

    $ sudo hostnamectl set-hostname hplaptop1

Make sure hostname is captured by one of the matchers in `manifests/nodes.pp`

Run the bootstrap script:

    wget -q -O - https://raw.github.com/AWooldrige/puppet/master/bootstrap.sh | sudo bash


3) Remove temporary user
------------------------
 1. Log in as woolie, check that sudo works correctly.
 2. Remove the temporary user that was only for puppet install.


4) Add credentials not managed by Puppet
----------------------------------------
Add the following as applicable:

 1. Transfer SSH keys from another machine if a workstation.
 2. Set `[ddns]` in `/home/woolie/.aws/credentials` if the machine uses
    raspi::ddns
 3. Set `/etc/nginx/secrets/photos.htpasswd` contents from password store if
    machine uses `raspi::photos`.
 3. Set `/etc/nginx/secrets/cg.htpasswd` contents from password store if
    machine uses `raspi::cg`.
 3. Restore backup to  `/var/ww/tw/ww` if machine uses `raspi::tiddlywiki`.


Development
================================
This is a masterless puppet configuration and works solely on puppet apply:

    make apply



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

To see log output for the main crons:

 * `sudo journalctl -t 'gdpup'`
 * `sudo journalctl -t 'ddns'`


Documentation
==============================

User strategy
------------------------------
Each machine has one main user, `woolie`. This user is used for SSH remote
access and local access. The user should always have a password set and should
also require it for sudo (no passwordless sudo, even on remote machines).
