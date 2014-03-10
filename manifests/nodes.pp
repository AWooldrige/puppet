###############################################################################
# WEBNODES
###############################################################################
#Local webnode Vagrant spinups
node "webnode.local.woolie.co.uk" inherits webnode { }

#Actual EC2 webnode
node /^ip-\d{1,3}-\d{1,3}-\d{1,3}-\d{1,3}$/ inherits webnode { }

###############################################################################
# RASPBERRY PI
###############################################################################
#Local pi Vagrant spinups
node /^pi.local.woolie.co.uk$/ inherits raspberry-pi { }

#Actual Raspberry PI
node /^pi-\d{1,3}.woolie.co.uk$/ inherits raspberry-pi { }
