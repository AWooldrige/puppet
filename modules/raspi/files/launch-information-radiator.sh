#!/usr/bin/env bash
killall chromium
DISPLAY=:0 /usr/bin/chromium --kiosk --disable-ipv6 \
"https://trello.com/b/ifd2Hyil/household" \
"https://www.google.com/calendar/render?tab=mc" \
"https://docs.google.com/a/woolie.co.uk/document/d/1LcO9leNghcEvGnkbH-suMoM9Oo3kr2KF48A9D4a88GQ/pub"\
&
