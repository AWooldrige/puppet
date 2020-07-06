.PHONY: apply
apply:
	./apply.sh

bundle.tar.gz: $(shell find modules manifests)
	tar -czf bundle.tar.gz --transform 's,^,puppet/,' .
