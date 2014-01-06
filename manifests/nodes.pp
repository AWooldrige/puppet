node "vagrant.woolie.co.uk" inherits headend { }
node /^ip-\d{1,3}-\d{1,3}-\d{1,3}-\d{1,3}$/ inherits headend { }
node /^pi-\d{1,3}.woolie.co.uk$/ inherits raspberry-pi { }
