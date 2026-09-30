#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
"""Watch the touchscreen for activity outside the browser."""

import datetime as dt
import logging
import os
import select
import threading

log = logging.getLogger("kitchen.activity")

_SELECT_TIMEOUT_SECONDS = 1.0
_READ_CHUNK_BYTES = 4096
_REOPEN_BACKOFF_SECONDS = 5.0


class TouchWatcher(threading.Thread):
    """
    Records a timestamp whenever the touchscreen produces any input.
    """

    daemon = True

    def __init__(self, device_path, on_activity):
        super().__init__(name="kitchen-touch")
        self.device_path = device_path
        self.on_activity = on_activity
        self._stopping = threading.Event()
        self._fd = None
        self.available = False

    def stop(self):
        self._stopping.set()

    def run(self):
        while not self._stopping.is_set():
            if self._fd is None and not self._open():
                # On a machine with no panel this is the normal steady state, so it
                # must not busy-loop.
                self._stopping.wait(_REOPEN_BACKOFF_SECONDS)
                continue
            self._pump()
        self._close()

    def _open(self):
        try:
            self._fd = os.open(self.device_path,
                               os.O_RDONLY | os.O_NONBLOCK)
            self.available = True
            log.info("watching %s for activity", self.device_path)
            return True
        except OSError as exc:
            log.debug("cannot open %s: %s", self.device_path, exc)
            self.available = False
            return False

    def _close(self):
        if self._fd is not None:
            try:
                os.close(self._fd)
            except OSError:
                pass
            self._fd = None
        self.available = False

    def _pump(self):
        try:
            readable, _, _ = select.select([self._fd], [], [],
                                           _SELECT_TIMEOUT_SECONDS)
        except (OSError, ValueError):
            self._close()
            return
        if not readable:
            return

        try:
            data = os.read(self._fd, _READ_CHUNK_BYTES)
        except BlockingIOError:
            return
        except OSError as exc:
            log.warning("read from %s failed: %s", self.device_path, exc)
            self._close()
            return

        if not data:
            # EOF means the device has been removed.
            self._close()
            return

        try:
            self.on_activity()
        except Exception:
            log.error("activity callback raised", exc_info=True)


class ActivityTracker:
    """
    Holds the last-activity timestamp. Safe to update from several threads.
    """

    def __init__(self, now=None):
        self._lock = threading.Lock()
        self._last = now or dt.datetime.now().astimezone()

    def note(self, when=None):
        with self._lock:
            self._last = when or dt.datetime.now().astimezone()

    @property
    def last(self):
        with self._lock:
            return self._last
