#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
import datetime as dt
import logging
import threading

from . import scheduler
from .activity import ActivityTracker, TouchWatcher
from .backlight import Backlight

log = logging.getLogger("kitchen.controller")

TICK_SECONDS = 1.0
HEARTBEAT_TICKS = 60


def _tz(name):
    try:
        from zoneinfo import ZoneInfo
        return ZoneInfo(name)
    except Exception:
        log.warning("unknown timezone %s, falling back to system local", name)
        return None


class Controller:
    def __init__(self, cfg, metrics, backlight=None, now_fn=None):
        self.cfg = cfg
        self.metrics = metrics
        schedule = cfg["schedule"]
        self.on_hour = schedule["on_hour"]
        self.off_hour = schedule["off_hour"]
        self.overnight_hold_minutes = schedule["overnight_hold_minutes"]
        self.revert_after_seconds = schedule["revert_after_seconds"]
        self._tzinfo = _tz(schedule["timezone"])

        self.backlight = backlight if backlight is not None else Backlight(cfg)
        self._now_fn = now_fn or self._now
        self.activity = ActivityTracker(now=self._now_fn())

        self._lock = threading.Lock()
        self._page = scheduler.BOARD_PAGE
        self._manual_off_at = None
        # The udev rule in raspi::touchdisplay unblanks the panel at boot
        self._screen_on = True
        self._revert_requested = False

        self._watcher = TouchWatcher(cfg["activity"]["device"],
                                     self.note_activity)
        self._stopping = threading.Event()
        self._thread = threading.Thread(target=self._loop,
                                        name="kitchen-controller", daemon=True)

    def _now(self):
        if self._tzinfo is not None:
            return dt.datetime.now(self._tzinfo)
        return dt.datetime.now().astimezone()

    def start(self):
        self._watcher.start()
        self._thread.start()
        log.info("screen schedule %02d:00-%02d:00, overnight hold %d min, "
                 "revert after %ds", self.on_hour, self.off_hour,
                 self.overnight_hold_minutes, self.revert_after_seconds)
        if not self.backlight.available:
            log.warning("no backlight device; screen control is a no-op")

    def stop(self):
        self._stopping.set()
        self._watcher.stop()

    def note_activity(self):
        self.activity.note(self._now_fn())

    def note_page(self, page):
        with self._lock:
            changed = page != self._page
            self._page = page
            if page == scheduler.BOARD_PAGE:
                # The browser has switched back, so clear the request.
                self._revert_requested = False
        if changed:
            self.metrics.send("tab_switch", 1, {"page": page})
            log.info("active tab: %s", page)
        self.note_activity()

    def request_screen(self, on):
        with self._lock:
            if on:
                self._manual_off_at = None
            else:
                self._manual_off_at = self._now_fn()
        if on:
            # Count the wake as activity, or the overnight rule would blank the panel
            # again on the next tick.
            self.note_activity()
        self.metrics.send("screen_request", 1 if on else 0)
        log.info("screen requested %s", "on" if on else "off")
        # Apply immediately rather than waiting up to a second for the next tick,
        # because this is a button press.
        self.tick()

    def snapshot(self):
        with self._lock:
            return {
                "screen_on": self._screen_on,
                "page": self._page,
                "revert_to_board": self._revert_requested,
                "backlight_available": self.backlight.available,
                "touch_available": self._watcher.available,
                "idle_seconds": round(
                    scheduler.seconds_since(self._now_fn(), self.activity.last)
                    or 0.0, 1),
            }

    def tick(self):
        now = self._now_fn()
        last_activity = self.activity.last

        with self._lock:
            manual_off_at = self._manual_off_at
            page = self._page
            was_on = self._screen_on
            was_reverting = self._revert_requested

        want_on = scheduler.screen_should_be_on(
            now, last_activity, manual_off_at, self.on_hour, self.off_hour,
            self.overnight_hold_minutes)

        woke = want_on and not was_on
        if want_on != was_on:
            self.backlight.set_on(want_on)
            self.metrics.send("screen_on", 1 if want_on else 0)

        # Only applies while the panel is lit.
        revert = want_on and scheduler.should_revert_to_board(
            page, now, last_activity, self.revert_after_seconds)

        # The main board is always displayed when the touchscreen is woken from
        # standby. The idle rule above cannot do this on its own.
        if woke and page != scheduler.BOARD_PAGE:
            revert = True

        if revert and not was_reverting:
            reason = "woke" if woke else f"{self.revert_after_seconds}s idle"
            self.metrics.send("tab_revert", 1, {"from": page, "reason": reason})
            log.info("reverting to the board from '%s' (%s)", page, reason)

        with self._lock:
            self._screen_on = want_on
            # Held until the browser reports it is back on the board
            self._revert_requested = was_reverting or revert

    def heartbeat(self):
        snapshot = self.snapshot()
        self.metrics.send("screen_on", 1 if snapshot["screen_on"] else 0)
        self.metrics.send("idle_seconds", snapshot["idle_seconds"])
        self.metrics.send("touch_available",
                          1 if snapshot["touch_available"] else 0)
        self.metrics.send("backlight_available",
                          1 if snapshot["backlight_available"] else 0)

    def _loop(self):
        ticks = 0
        while not self._stopping.is_set():
            try:
                self.tick()
                if ticks % HEARTBEAT_TICKS == 0:
                    self.heartbeat()
            except Exception:
                log.error("controller tick raised", exc_info=True)
            ticks += 1
            self._stopping.wait(TICK_SECONDS)
