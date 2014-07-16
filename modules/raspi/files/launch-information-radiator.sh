#!/usr/bin/env bash
killall chromium
DISPLAY=:0 /usr/bin/chromium --kiosk --disable-ipv6 \
"https://trello.com/b/ifd2Hyil/household" \
"https://www.google.com/calendar/render?tab=mc" \
&
