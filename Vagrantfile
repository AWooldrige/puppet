# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    config.vm.box = "ubuntu13.10"
    config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/saucy/20131208/saucy-server-cloudimg-amd64-vagrant-disk1.box"

    config.vm.hostname = "vagrant.woolie.co.uk"
    config.vm.network "private_network", ip: "192.168.42.42"

    config.vm.provision "shell", path: "bootstrap.sh"
    config.vm.synced_folder "~/.ssh", "/host-ssh-keys", :mount_options => ["dmode=755","fmode=440"]
end
