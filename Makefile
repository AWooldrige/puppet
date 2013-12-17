apply:
	sudo puppet apply --modulepath=modules manifests/site.pp -vv

vagrant:
	vagrant up
	ssh vagrant -t 'bash -l -c "populate-workspace"'
