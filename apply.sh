#!/usr/bin/env bash
set -eu
sudo puppet apply -v --strict_variables --modulepath=/etc/puppet/code/modules/:/etc/securepuppet/modules/:./modules/ ./manifests/
echo "Complete. Don't forget that gdpup may eventually overwrite changes made by this puppet run"
