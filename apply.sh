#!/usr/bin/env bash
set -eu
sudo puppet apply -v --strict_variables --modulepath=/etc/puppet/code/modules/:/etc/securepuppet/modules/:./modules/ ./manifests/
echo "Complete. Don't forget that gdpup may eventually overwrite changes made by this puppet run"

if ! passwd -S woolie | grep '^woolie P ' > /dev/null; then
    echo "FAIL";
    echo "ERROR: User account 'woolie' has no password set."
    echo "    -> DO NOT REBOOT OR LOG OUT"
    echo "    -> SET PASSWORD IMMEDIATELY, USING: passwd woolie"
    exit 1
fi
