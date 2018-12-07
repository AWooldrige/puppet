#!/usr/bin/env bash
set -eu

GPATH="/etc/gdpup-bootstrap"

# Script principle:
# 1) Idempotent. It should be possible to run this script multiple times.

function install {
    dpkg -s "$1" && return 0
    for attempt in {1..5}; do
        if ! apt install -y "$1"; then
            echo "Could not install ${1} after attempt ${attempt}"
            apt update -y --fix-missing
            sleep 2
        else
            break
        fi
    done
}

echo 'Upgrading packages'
apt update -y
apt upgrade -y

echo 'Installing git and puppet'
install git
install puppet

echo "Removing any current puppet code from $GPATH"
rm -rf "$GPATH"

echo 'Shallow cloning puppet git repo from master'
git clone --depth=1 https://github.com/AWooldrige/puppet.git "$GPATH"

echo 'Running puppet'
puppet apply -v "--modulepath=${GPATH}/modules" "${GPATH}/manifests"

echo "Removing $GPATH"
rm -rf "$GPATH"

# https://unix.stackexchange.com/a/465438
case $(passwd --status woolie | awk '{print $2}') in
    NP)  echo "No password set for 'woolie', set one:"
        passwd woolie
        ;;
    L)  echo "Account 'woolie' is locked, set password"
        passwd woolie
        ;;
    P)  echo "Password already set for 'woolie'" ;;
esac
exit 1

echo 'Finished. Remember to delete temporary user.'
