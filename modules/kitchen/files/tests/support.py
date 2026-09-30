#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
"""
Shared test fixtures.

The config here must stay a faithful copy of what config.toml.epp renders, since
config.py has no defaults: a key missing from the template shows up as a KeyError in
these tests rather than at 3am on the kitchen wall.
"""

import datetime as dt

from kitchen import config as config_mod

CONFIG_TEMPLATE = """
[server]
bind = "127.0.0.1"
port = 5273

[calendar]
timezone = "Europe/London"
lookahead_days = 60
calendar_ids = ["a@example.com", "b@example.com"]
service_account_file = "{state_dir}/service-account.json"

[weather]
latitude = 51.5
longitude = -0.1
timezone = "Europe/London"
cache_minutes = 10
max_stale_hours = 6
forecast_days = 3

[refresh]
interval_minutes = 30
min_manual_interval_seconds = 10

[state]
dir = "{state_dir}"
stale_hours = 6

[health]
upstream_host = "192.168.50.7"
upstream_port = 443
check_timeout_seconds = 2

[metrics]
enabled = false
host = "127.0.0.1"
port = 8094
measurement = "kitchen"

[tabs]
home_url = "http://127.0.0.1:5274/"
graphs_url = "http://127.0.0.1:5275/grafana/?refresh=1m"

[schedule]
timezone = "Europe/London"
on_hour = 6
off_hour = 21
overnight_hold_minutes = 5
revert_after_seconds = 120

[backlight]
device_glob = "/sys/class/backlight/panel_backlight*"

[activity]
device = "/dev/input/kitchen-touch"
"""


def make_config(state_dir):
    return config_mod.loads(CONFIG_TEMPLATE.format(state_dir=state_dir))


def raw_all_day(summary, start, end):
    """A Google all-day event. Google's end date is exclusive."""
    return {"summary": summary, "start": {"date": start}, "end": {"date": end}}


def raw_timed(summary, start, end, location=None):
    event = {"summary": summary, "start": {"dateTime": start},
             "end": {"dateTime": end}}
    if location:
        event["location"] = location
    return event


def london_now(year, month, day, hour=9, minute=0):
    from kitchen.calendar_source import _tz
    return dt.datetime(year, month, day, hour, minute,
                       tzinfo=_tz("Europe/London"))
