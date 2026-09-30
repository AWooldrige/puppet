#!/usr/bin/env bash
# Rsync this working tree to a host, so local edits can be applied without
# committing. Needs puppet installed: run bootstrap.sh first.
#
#   sync_to_host.sh ktcdh1
#   sync_to_host.sh --apply --watch ktcdh1
#   sync_to_host.sh -p 22 --apply tmpbootstrap@192.168.50.9
#
# One shot unless --watch
set -eu

watch=
apply=
port=
dest=

while [ $# -gt 0 ]; do
    case "$1" in
        -w|--watch) watch=1 ;;
        -a|--apply) apply=1 ;;
        -p|--port) port="${2:?-p needs a port}"; shift ;;
        -*) echo "unknown option: $1" >&2; exit 2 ;;
        *) dest="$1" ;;
    esac
    shift
done

if [ -z "${dest}" ]; then
    echo "usage: sync_to_host.sh [--watch] [--apply] [-p port] <ssh destination>" >&2
    exit 2
fi

ssh_cmd=(ssh)
if [ -n "${port}" ]; then
    ssh_cmd+=(-p "${port}")
fi

function push {
    rsync -az --delete --exclude .git --exclude __pycache__ \
        -e "${ssh_cmd[*]}" . "${dest}:puppet_rsync_copy"

    if [ -n "${apply}" ]; then
        "${ssh_cmd[@]}" -t "${dest}" 'cd puppet_rsync_copy && ./apply.sh'
    fi
}

push

if [ -z "${watch}" ]; then
    if [ -z "${apply}" ]; then
        echo "Synced. To apply: ssh ${dest} 'cd puppet_rsync_copy && ./apply.sh'"
    fi
    exit 0
fi

echo "Watching for changes. Ctrl-C to stop."
while inotifywait -qq -e create,modify,delete -r .; do
    push
    echo "[$(date --rfc-3339=seconds)] re-synced"
done
