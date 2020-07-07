Bootstrapping a system from scratch
===================================

1) Install OS
-------------
For Raspberry Pi:

 1. Connect with ethernet and SSH to local IP with `ssh -o IdentitiesOnly=yes
    ubuntu@<IP>`

For Ubuntu Desktops:

 1. Enable full drive encryption during install. This reduces risk from
    hardware theft.
 2. Do not create a user named `woolie` as part of setup, instead create a
    temporary user named 'tmpbootstrap'. This will only be used to run puppet
    initially and should be removed after. Puppet needs to create the `woolie`
    user to keep UIDs/GIDs in sync.
 3. Set hostname if asked, following scheme of {model}{increment}.


2) Run puppet
-------------

 1. If bootstrapping a host that needs a static IP, ensure the router
    configuration is set as in this README. If changing a hardware used for the
    same host, update the MAC address in the README/router.
 2. Set hostname with `sudo hostnamectl set-hostname "{model}{increment}`
 3. Copy secure puppet module from password manager to
    `/etc/securepuppet/modules/secure/manifests/init.pp` then `chmod -R 600
    /etc/securepuppet`
 4. Run the bootstrap script:

    wget -q -O - https://raw.github.com/AWooldrige/puppet/master/bootstrap.sh | sudo bash


3) Add credentials not managed by Puppet
----------------------------------------
For workstations:

 1. Transfer SSH keys from another machine.

For webpi:

 2. Set `[ddns]` in `/home/woolie/.aws/credentials`
 3. Set `/etc/nginx/secrets/photos.htpasswd` contents from password store
 3. Set `/etc/nginx/secrets/cg.htpasswd` contents from password store
 3. Restore tiddlywiki backup using `/var/ww/tw/ww`
 3. Install pihole using instructions from [https://pi-hole.net/]


Router configuration
====================

DHCP reservations
-----------------
| Description | MAC | Reserved IP |
| webpi Raspberry Pi 4 | dc:a6:32:8b:96:48 | 192.168.0.201 |
| epaperpi Raspberry Pi 3 | b8:27:eb:3c:0c:11 | 192.168.0.202 |

Port forwarding
---------------
| Description | Protocol | External port | Local port | Local IP |
| SSH (slightly obsfucated) to webpi | TCP + UDP | 3222 | 3222 | 192.168.0.201 |
| HTTP to webpi | TCP + UDP | 80 | 80 | 192.168.0.201 |
| HTTPS to webpi | TCP + UDP | 443 | 443 | 192.168.0.201 |


Puppet config conventions
=========================

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
