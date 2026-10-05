#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
"""
WiFi quality and timestamp helpers for the board's status footer.
"""

import datetime as dt
import glob
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


def _read(path):
    try:
        with open(path, "r", encoding="utf-8") as handle:
            return handle.read()
    except OSError:
        return None


def parse_uptime(text):
    try:
        return int(float(text.split()[0]))
    except (AttributeError, IndexError, ValueError):
        return None


def uptime_seconds(path="/proc/uptime"):
    return parse_uptime(_read(path))


def parse_cpu_temp(text):
    try:
        return round(int(text.strip()) / 1000, 1)
    except (AttributeError, ValueError):
        return None


def cpu_temp_c(path="/sys/class/thermal/thermal_zone0/temp"):
    return parse_cpu_temp(_read(path))


def parse_memory_available(text):
    fields = {}
    for line in (text or "").splitlines():
        name, _, rest = line.partition(":")
        parts = rest.split()
        if parts and parts[0].isdigit():
            fields[name.strip()] = int(parts[0])
    total = fields.get("MemTotal")
    available = fields.get("MemAvailable")
    if not total or available is None:
        return None
    return round(available / total * 100)


def memory_percent_available(path="/proc/meminfo"):
    return parse_memory_available(_read(path))


def disk_free_bytes(path="/"):
    try:
        stat = os.statvfs(path)
    except OSError:
        return None
    return stat.f_bavail * stat.f_frsize


def parse_alarm(text):
    if text is None:
        return None
    value = text.strip()
    if value not in ("0", "1"):
        return None
    return value == "1"


def under_voltage(pattern="/sys/class/hwmon/hwmon*/in0_lcrit_alarm"):
    for path in sorted(glob.glob(pattern)):
        alarm = parse_alarm(_read(path))
        if alarm is not None:
            return alarm
    return None


def next_refresh(cfg, now=None):
    now = now or dt.datetime.now()
    minutes = cfg["refresh"]["interval_minutes"]
    return (now + dt.timedelta(minutes=minutes)).strftime("%H:%M")
