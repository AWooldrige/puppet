apply:
	sudo puppet apply --modulepath=modules manifests/site.pp -vv

vagrant:
	vagrant up
	ssh vagrant -t 'bash -l -c "populate-workspace"'

path = ~/puppet_makefile_deploy
deploy_to_pi:
	ssh home 'rm -rf $(path); mkdir $(path)'
	scp -C -r ./* home:$(path)
	ssh home 'cd $(path) && make apply'
