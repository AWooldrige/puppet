# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    config.vm.synced_folder "~/.ssh", "/host-ssh-keys", :mount_options => ["dmode=755","fmode=440"]

    config.vm.define :webnode do |webnode_local|
        webnode_local.vm.box = "ubuntu_13.10"
        webnode_local.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/saucy/current/saucy-server-cloudimg-amd64-vagrant-disk1.box"

        webnode_local.vm.hostname = "webnode.local.woolie.co.uk"
        webnode_local.vm.network "private_network", ip: "192.168.42.42"

        webnode_local.vm.provision "shell", path: "bootstrap.sh"
    end
end
