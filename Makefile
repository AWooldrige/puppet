apply:
	sudo puppet apply --modulepath=/etc/puppet/code/modules/:./modules/ ./manifests/ -vvv

bundle.tar.gz: $(shell find modules manifests)
	tar -czf bundle.tar.gz --transform 's,^,puppet/,' .
