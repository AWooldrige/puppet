Bootstrapping a system from scratch
===================================

## 1) Install Ubuntu
If installing on Raspberry Pi SD card. From a workstation:

 1. Raspberry Pi Imager
 2. Other general-purpose OS -> Ubuntu, Server or Desktop LTS
 3. Skip OS customisation.
 4. Eject and reinsert, ready to seed with provisioning step next.

If installing on workstation from live CD/USB:

 1. Enable full drive encryption.
 2. Create a temporary user `tmpbootstrap`, not `woolie` (Puppet creates
    `woolie`).
 3. Set the hostname per naming convention below.


## 2) Prepare the workstation to perform the provisioning

The remaining steps run from a workstation. Keep `puppet` and
`puppet-secure` in the same directory, e.g.:

    ~/checkouts/puppet
    ~/checkouts/puppet-secure

Restore the age credential at `~/.config/sops/age/keys.txt`, setting mode
`0600`. Edit `fleet.yaml` with SOPS:

    cd ~/checkouts/puppet-secure
    sops fleet.yaml

Add the host's role and any host specific values. For a Raspberry Pi, add one
static address for every interface needed. For example, a Pi with both Ethernet
and WiFi gets two addresses:

    blrsh1:
      role: pi
      addresses:
        eth0: 192.168.50.5
        wlan0: 192.168.50.6

Workstations normally omit `addresses` entirely and use DHCP.

Return to the provisioning tools and configure temporary env vars:

    cd ~/checkouts/puppet/provision
    S=../../puppet-secure
    H=ktcdh1
    IP=192.168.50.9

`IP` is separate from the `addresses` map. It's just the one address the
workstation uses to connect to the host during bootstrap. For a workstation,
`IP` must be set as its current DHCP address.

Issue the client cert (do not issue a replacement certificate after a
re-flash):

    ./issue_cert.py $H --ca-key $S/ca/root-ca.key.yaml --store $S/certs/$H.yaml

Issue a server cert as well, if needed:

    ./issue_cert.py $H --ca-key $S/ca/root-ca.key.yaml --server --store $S/certs/$H-server.yaml


## 3) Provisioning a headless Raspberry Pi

 1. Write the cloud-init config to the SD card:

       ./provision.py $H --fleet $S/fleet.yaml --seed /run/media/woolie/system-boot

 2. Insert the SD card and boot the Pi, wait enough time (possibly an hour+ on
    older Pis) for cloud-init and unattended-upgrades to run. For desktop
    images, also wait until the SSH server is installed by cloud-init.
 3. Connect over port 22:

       ssh tmpbootstrap@$IP

 4. Push the certificates and rendered secure module:

       ./provision.py $H --fleet $S/fleet.yaml --certs $S/certs --ssh tmpbootstrap@$IP

 5. Install Puppet and apply (also see section 5 on applying changes not yet
    pushed):

       ssh tmpbootstrap@$IP 'wget -qO- https://raw.github.com/AWooldrige/puppet/master/bootstrap.sh | sudo bash'

    This moves SSH to port 3222 and ends non-zero while `tmpbootstrap` exists.

 6. Connect as woolie on the new port, then remove the temporary account:

       ssh -p 3222 woolie@$IP
       sudo userdel -r tmpbootstrap
       sudo rm /etc/sudoers.d/90-cloud-init-users

 7. Run the apply again through the new account so Puppet finishes cleanly:

       ssh -t -p 3222 woolie@$IP 'sudo /root/puppet/apply.sh'

## 4) Interactive workstation

Same as section 3 from step 3 onwards, no seed and no static address. Two
differences:

 1. The interactive installer replaces step 1. Create `tmpbootstrap`, set the
    hostname, install and enable SSH, then add the public key from
    `modules/woolie/manifests/ubuntuprefs.pp` to `tmpbootstrap`'s
    `~/.ssh/authorized_keys`.
 2. Workstations don't have their password managed, so keep the bootstrap
    SSH session open and set it by hand before deleting `tmpbootstrap`:

       sudo passwd woolie


## 5) Applying puppet changes that are not pushed

`bootstrap.sh` clones from GitHub, if needing to apply from a local copy:

 1. Seed or install as above, then push the certificates and secure module.
 2. Install Puppet and the modules without applying:

       ssh tmpbootstrap@$IP 'sudo env SKIP_APPLY=1 bash -s' < bootstrap.sh

 3. Apply the local tree (syncs to `~/puppet_rsync_copy`, runs `apply.sh`):

       ./sync_to_host.sh -p 22 --apply tmpbootstrap@$IP


The secret store
================
`puppet-secure` is a private repo, encrypted using sops + age.

    .sops.yaml                age recipient
    fleet.yaml                fleet and per-host secrets
    ca/root-ca.key.yaml       root CA private key
    certs/<host>.yaml         issued leaf certificates
    certs/<host>-server.yaml  issues server certificates

The age identity is kept separate. On a new machine paste all three lines
into `~/.config/sops/age/keys.txt`, then set 600.

These credentials also live elsewhere:

 * Workstation LUKS passphrases
 * Home Assistant's backup encryption key


Certificates for phones
=======================

    ./issue_cert.py pxlmh1 --ca-key $S/ca/root-ca.key.yaml \
        --store $S/certs/pxlmh1.yaml --p12-out ~/pxlmh1.p12

Android: Settings -> Security -> Encryption & credentials -> Install a
certificate -> VPN & app user certificate

Add the CN to `$wiki_allowed` in
`modules/nginx/files/conf.d/client-authorisation.conf`


Main desktop extras (lendh1)
============================
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
 6. `mv /media/woolie/bulkstorage/Dropbox_old/* /media/woolie/bulkstorage/Dropbox/`
 7. Start Dropbox again and wait a long time for it to index.


Naming convention
=================

All lowercase

| Char | Field | Options |
| ---- | ----- | ------- |
| 1-3  | Purpose | (free choice) |
| 4    | Type | d:desktop, s:server, m:mobile |
| 5    | Location | h:home |
| 6+   | Unique num | 1 onwards |

Character 4 also becomes the certificate's OU, derived by `issue_cert.py`.

Allocated hostnames:

 * websh1
 * ktcdh1
 * blrsh1
 * pxlmh1 (phone, certificate only, no Puppet)


Router configuration
====================

Static addresses
----------------

Set on the machines by `raspi::network`, from the `addresses` map in
`fleet.yaml`. Router DHCP pool configured to not start before `.100`.

| Description | Address |
| ----------- | ------- |
| blrsh1 Pi 3 eth0 | 192.168.50.5 |
| blrsh1 Pi 3 wlan0 | 192.168.50.6 |
| websh1 Pi 5 eth0 | 192.168.50.7 |
| websh1 Pi 5 wlan0 | 192.168.50.8 |
| ktcdh1 Pi 4 wlan0 | 192.168.50.9 |


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
Each file that gets written to a host's filesystem should be prepended with the
following text:

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
 * `sudo journalctl -t 'kitchen'`
 * `sudo journalctl -t 'panel-backlight'`
