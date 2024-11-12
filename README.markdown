Bootstrapping a system from scratch
===================================

1) Install OS
-------------
For Raspberry Pi:

 1. Install latest Ubuntu server LTS.
 2. Connect with ethernet and SSH to local IP with `ssh -o
    PasswordAuthentication=yes -o
    PreferredAuthentications=keyboard-interactive,password -o
    PubkeyAuthentication=no ubuntu@<IP>`

For Ubuntu Desktops:

 1. Enable full drive encryption during install. This reduces risk from
    hardware theft.
 2. Do not create a user named `woolie` as part of setup, instead create a
    temporary user named 'tmpbootstrap'. This will only be used to run puppet
    initially and should be removed after. Puppet needs to create the `woolie`
    user to keep UIDs/GIDs in sync.
 3. Set hostname if asked, following scheme of {model}{increment}.


For main desktop to auto decrypt and mount the internal SATA HDD:

 1. Configure auto unlocking of partition:
     1. Retrieve password from password manager for drive starting UUID=cd5e45c0
     2. Open GNOME disks.
     3. Select LUKS partition on drive (not the filesystem).
     4. Additional partition options > Edit Encryption Options.
     5. Uncheck "User Session Defaults".
     6. Check "Unlock at system startup".
     7. Enter passphrase from manager.
 2. Configure auto mounting of filesystem:
     1. Select the filesystem (not the partition) in GNOME disks.
     2. Additional partition options -> Edit Mount Options.
     3. Uncheck "User Session Defaults".
     4. Check "Mount at system startup"
     5. Set mount point: `/media/woolie/bulkstorage`.

For main desktop to get Dropbox client running again:

 1. `mv /media/woolie/bulkstorage/Dropbox /media/woolie/bulkstorage/Dropbox_old`
 2. Install Dropbox and sign in.
 3. Change Dropbox storage location to `/media/woolie/bulkstorage` (it will create a `/Dropbox` dir within).
 4. Quit/stop the Dropbox application (very important).
 5. `rm -rf /media/woolie/bulkstorage/Dropbox/*`
 6. `mv /media/woolie/bulkstorage/Dropbox_tmpold/* /media/woolie/bulkstorage/Dropbox/`
 7. Start Dropbox again and wait a long time for it to index.



2) Run puppet
-------------

 1. If bootstrapping a host that needs a static IP, ensure the router
    configuration is set as in this README. If changing a hardware used for the
    same host, update the MAC address in the README/router.
 2. Set hostname with `sudo hostnamectl set-hostname "{model}{increment}`
 3. Run the bootstrap script: `wget -q -O - https://raw.github.com/AWooldrige/puppet/master/bootstrap.sh | sudo bash`


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


Naming convention
=================

All lowercase

| Char | Field | Options |
| ---- | ----- | ------- |
| 1-3  | Purpose | (free choice) |
| 4    | Type | d:desktop, s:server |
| 5    | Location | h:home |
| 6+   | Unique num | 1 onwards |


Allocated hostnames:

 * websh1



Router configuration
====================

DHCP reservations
-----------------

| Description | MAC | Reserved IP |
| ----------- | --- | ----------- |
| webpi Pi 4 eth0 | dc:a6:32:8b:96:48 | 192.168.50.2 |
| epaperpi Pi 3 eth0 | b8:27:eb:3c:0c:11 | 192.168.50.3 |
| epaperpi Pi 3 wlan0 | b8:27:eb:69:59:44 | 192.168.50.4 |
| boilerpi Pi 2 eth0 | B8:27:EB:6F:AF:69 | 192.168.50.5 |
| boilerpi Pi 2 wlan0 | 80:1f:02:af:5a:81 | 192.168.50.6 |
| websh1 Pi 5 eth0 | 2C:CF:67:27:0C:D7 | 192.168.50.7 |
| websh1 Pi 5 wlan0 | TODO | 192.168.50.8 |

These also have convenience DNS entries created under
`<hostname>.wooldrige.co.uk`.


Port forwarding
---------------

| Description | Protocol | External port | Local port | Local IP |
| ----------- | -------- | ------------- | ---------- | -------- |
| SSH (slightly obsfucated) to websh1 | TCP + UDP | 3222 | 3222 | 192.168.50.7 |
| HTTP to websh1 | TCP + UDP | 80 | 80 | 192.168.50.7 |
| HTTPS to websh1 | TCP + UDP | 443 | 443 | 192.168.50.7 |


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
