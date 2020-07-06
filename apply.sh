#!/usr/bin/env bash
set -eu
sudo puppet apply --modulepath=/etc/puppet/code/modules/:./modules/ ./manifests/ -vvv
echo "Complete. Don't forget that gdpup may eventually overwrite changes made by this puppet run"
