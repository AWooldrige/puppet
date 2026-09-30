.PHONY: apply test test-python test-shell test-provision

apply:
	./apply.sh

test: test-python test-shell test-provision

test-python:
	cd modules/kitchen/files && python3 -B -m unittest discover -v

test-shell:
	./modules/kitchen/files/tests/test_panel_backlight_init.sh
	./modules/gdpup/files/tests/test_gdpup.sh

test-provision:
	cd provision && python3 -B -m unittest discover -v

bundle.tar.gz: $(shell find modules manifests)
	tar -czf bundle.tar.gz --transform 's,^,puppet/,' .
