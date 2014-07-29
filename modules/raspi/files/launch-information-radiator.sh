#!/usr/bin/env bash
set -e

function log {
    echo $(date --rfc-3339=ns)" ${1}"
}

if killall chromium; then
    log "Killed existing chromium process";
else
    log "No existing chromium process running";
fi

DISPLAY=:0 /usr/bin/chromium --kiosk --disable-ipv6 \
"https://trello.com/b/ifd2Hyil/household" \
&
