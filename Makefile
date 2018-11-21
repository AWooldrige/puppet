apply:
	sudo puppet apply --modulepath=modules/ manifests/ -vv

vagrant:
	vagrant up
	ssh vagrant -t 'bash -l -c "populate-workspace"'

path = ~/puppet_makefile_deploy
.PHONY: copy_to_pi
copy_to_pi:
	ssh pi-1 'rm -rf $(path) && mkdir $(path)'
	scp -C -r ./* pi-1:$(path)
