#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
import datetime as dt
import json
import logging
import os

log = logging.getLogger("kitchen.envelopes")

SCHEMA = 1
_FILE_NAME = "envelopes_last_good.json"
_ENVELOPE_KEYS = ("name", "frequency", "balance", "monthly_budget",
                  "pct_remaining", "total_spend", "total_receive", "transactions")


def _path(cfg):
    return os.path.join(cfg["state"]["dir"], _FILE_NAME)


def validate(data):
    if not isinstance(data, dict) or data.get("schema") != SCHEMA:
        raise ValueError(f"unexpected envelope summary schema: "
                         f"{data.get('schema') if isinstance(data, dict) else type(data)}")
    for key in ("generated_at", "budget_start", "budget_end"):
        dt.date.fromisoformat(data[key][:10])
    for group in ("key", "longer_term"):
        if not isinstance(data[group], list):
            raise ValueError(f"{group} is not a list")
        for envelope in data[group]:
            missing = [k for k in _ENVELOPE_KEYS if k not in envelope]
            if missing:
                raise ValueError(f"envelope missing {missing}")


def refresh(cfg, metrics=None):
    e = cfg["envelopes"]
    try:
        import requests
        resp = requests.get(e["url"], timeout=e["timeout_seconds"])
        resp.raise_for_status()
        data = resp.json()
        validate(data)
        part = _path(cfg) + ".part"
        with open(part, "w", encoding="utf-8") as handle:
            json.dump(data, handle)
        os.replace(part, _path(cfg))
        if metrics:
            metrics.send("envelopes_ok", 1)
            metrics.send("envelopes_age_days", age_days(data))
        return True
    except Exception:
        log.error("envelope summary fetch failed", exc_info=True)
        if metrics:
            metrics.send("envelopes_ok", 0)
        return False


def age_days(data, today=None):
    today = today or dt.date.today()
    return (today - dt.date.fromisoformat(data["generated_at"][:10])).days


def current(cfg, today=None):
    try:
        with open(_path(cfg), "r", encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, ValueError):
        return None
    data["age_days"] = age_days(data, today)
    data["stale"] = data["age_days"] > cfg["envelopes"]["stale_after_days"]
    return data
