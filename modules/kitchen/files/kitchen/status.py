#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
"""
WiFi quality and timestamp helpers for the board's status footer.
"""

import datetime as dt
import logging
import os

log = logging.getLogger("kitchen.status")

_WIFI_QUALITY_MAX = 70.0  # /proc/net/wireless link quality scale


def parse_wifi_percent(proc_contents, interface=None):
    for line in proc_contents.splitlines():
        line = line.strip()
        if ":" not in line:
            continue
        name, _, rest = line.partition(":")
        name = name.strip()
        if interface and name != interface:
            continue
        fields = rest.split()
        if len(fields) < 2:
            continue
        try:
            link = float(fields[1].rstrip("."))
        except ValueError:
            continue
        pct = int(round(min(link, _WIFI_QUALITY_MAX) / _WIFI_QUALITY_MAX * 100))
        return max(0, min(100, pct))
    return None


def wifi_percent(path="/proc/net/wireless"):
    try:
        with open(path, "r", encoding="utf-8") as handle:
            return parse_wifi_percent(handle.read())
    except OSError:
        return None


def load_average():
    try:
        one_minute, _, _ = os.getloadavg()
    except OSError:
        return None
    return round(one_minute, 1)


def next_refresh(cfg, now=None):
    now = now or dt.datetime.now()
    minutes = cfg["refresh"]["interval_minutes"]
    return (now + dt.timedelta(minutes=minutes)).strftime("%H:%M")
