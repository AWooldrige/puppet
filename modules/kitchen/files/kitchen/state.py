#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
import datetime as dt
import json
import logging
import os
import time

log = logging.getLogger("kitchen.state")


class State:
    def __init__(self, cfg):
        self.cfg = cfg
        self.dir = cfg["state"]["dir"]
        self.stale_hours = cfg["state"]["stale_hours"]
        self.snapshot_path = os.path.join(self.dir, "last_good.json")
        self.last_success_path = os.path.join(self.dir, "last_success")

    def save_success(self, snapshot):
        self._ensure_dir()
        _atomic_write_text(self.snapshot_path,
                           json.dumps(snapshot, separators=(",", ":")))
        _atomic_write_text(self.last_success_path, str(int(time.time())))

    def load_snapshot(self):
        try:
            with open(self.snapshot_path, "r", encoding="utf-8") as handle:
                return json.load(handle)
        except (OSError, ValueError):
            return None

    def get_success_time(self):
        try:
            with open(self.last_success_path, "r", encoding="utf-8") as handle:
                return dt.datetime.fromtimestamp(int(handle.read().strip()))
        except (OSError, ValueError):
            return None

    def success_age_seconds(self, now=None):
        ts = self.get_success_time()
        if ts is None:
            return None
        now = now or dt.datetime.now()
        return (now - ts).total_seconds()

    def is_stale(self, now=None):
        """
        Whether the newest good data is older than stale_hours.
        """
        age = self.success_age_seconds(now)
        if age is None:
            return True
        return age > self.stale_hours * 3600

    def _ensure_dir(self):
        try:
            os.makedirs(self.dir, exist_ok=True)
        except OSError:
            log.warning("could not create state dir %s", self.dir)


def _atomic_write_text(path, text):
    tmp = f"{path}.tmp"
    with open(tmp, "w", encoding="utf-8") as handle:
        handle.write(text)
    os.replace(tmp, path)
