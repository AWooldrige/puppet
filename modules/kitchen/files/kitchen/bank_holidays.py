#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
import json
import logging
import os
import time

log = logging.getLogger("kitchen.bank_holidays")

_CACHE_NAME = "bank_holidays_cache.json"


def _cache_path(cfg):
    return os.path.join(cfg["state"]["dir"], _CACHE_NAME)


def _read_cache(cfg):
    try:
        with open(_cache_path(cfg), "r", encoding="utf-8") as handle:
            return json.load(handle)
    except (OSError, ValueError):
        return None


def _write_cache(cfg, holidays):
    try:
        with open(_cache_path(cfg), "w", encoding="utf-8") as handle:
            json.dump({"ts": time.time(), "holidays": holidays}, handle)
    except OSError:
        log.debug("could not write bank holiday cache")


def parse(data, division):
    events = data[division]["events"]
    return {event["date"]: event["title"] for event in events}


def fetch(cfg, metrics=None):
    bh = cfg["bank_holidays"]
    cached = _read_cache(cfg)
    if cached and time.time() - cached.get("ts", 0) < bh["cache_hours"] * 3600:
        return cached["holidays"]

    try:
        import requests
        resp = requests.get(bh["url"], timeout=10)
        resp.raise_for_status()
        holidays = parse(resp.json(), bh["division"])
        _write_cache(cfg, holidays)
        if metrics:
            metrics.send("bank_holidays_success", 1)
        return holidays
    except Exception:
        log.error("bank holiday fetch failed", exc_info=True)
        if metrics:
            metrics.send("bank_holidays_success", 0)
        return cached["holidays"] if cached else {}
