#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
"""
Serves the shell page and the JSON API on 127.0.0.1, fetches and caches
calendar and weather on a background timer, drives the panel via controller.py.
"""

import argparse
import datetime as dt
import json
import logging
import mimetypes
import os
import posixpath
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from . import board as board_mod
from . import config as config_mod
from . import logging_setup
from . import state as state_mod
from .metrics import Metrics, NullMetrics

log = logging.getLogger("kitchen.app")

STATIC_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "static")
_MAX_BODY_BYTES = 4096


class BoardCache:
    """
    Holds the current payload and controls when a new one is fetched.

    The HTTP handlers never fetch, they read whatever is here. This keeps a button
    press responsive and stops a slow Google call queueing up behind itself when
    several tabs poll at once.
    """

    def __init__(self, cfg, state, metrics):
        self.cfg = cfg
        self.state = state
        self.metrics = metrics
        self._lock = threading.Lock()
        self._payload = None
        self._last_attempt = 0.0
        self._refreshing = threading.Lock()

    def current(self):
        with self._lock:
            if self._payload is not None:
                return self._payload
        # Nothing in memory yet, so fall back to the last good snapshot on disk.
        stale = board_mod.stale_payload(self.cfg, self.state)
        if stale is not None:
            with self._lock:
                if self._payload is None:
                    self._payload = stale
            return stale
        return None

    def refresh(self):
        """
        Fetch and publish. Returns True when live data was published.

        Only one fetch runs at a time. A second caller while a fetch is in flight
        returns immediately rather than queueing a duplicate.
        """
        if not self._refreshing.acquire(blocking=False):
            log.info("refresh already in progress, skipping")
            return False
        try:
            self._last_attempt = time.monotonic()
            start = time.monotonic()
            payload = board_mod.build(self.cfg, self.state, self.metrics)
            duration = round(time.monotonic() - start, 3)
            self.metrics.send("refresh_seconds", duration)

            if payload["health"]["calendar_ok"]:
                # Only persist a successful calendar fetch, or real events would be
                # overwritten with an empty list.
                self.state.save_success(payload)
                self.metrics.send("refresh_success", 1)
                with self._lock:
                    self._payload = payload
                log.info("refreshed: %d events in %ss",
                         payload["event_count"], duration)
                return True

            self.metrics.send("refresh_success", 0)
            fallback = board_mod.stale_payload(self.cfg, self.state)
            with self._lock:
                # Old but real events are more use than an empty board.
                self._payload = fallback if fallback is not None else payload
            log.warning("refresh failed; serving %s",
                        "last-good snapshot" if fallback else "empty board")
            return False
        except Exception:
            log.error("refresh raised", exc_info=True)
            self.metrics.send("refresh_success", 0)
            return False
        finally:
            self._refreshing.release()


class RefreshLoop(threading.Thread):
    """
    Background refresh on the configured cadence, or sooner if the date moves.
    """

    daemon = True
    DATE_CHECK_SECONDS = 20

    def __init__(self, cache, interval_seconds, today_fn=None):
        super().__init__(name="kitchen-refresh")
        self.cache = cache
        self.interval_seconds = interval_seconds
        self.today_fn = today_fn or dt.date.today
        self._wake = threading.Event()
        self._stopping = False

    def run(self):
        while not self._stopping:
            self.cache.refresh()
            self._wait_until_stale(self.today_fn())
            self._wake.clear()

    def _wait_until_stale(self, rendered_for):
        """
        Wait out the interval, but give up early if the calendar is now showing the
        wrong day. That happens at midnight, and on a Pi with no clock battery when
        chrony steps the time forward seconds after the board has already started
        and rendered a date from whenever the image was built.
        """
        deadline = time.monotonic() + self.interval_seconds
        while not self._stopping:
            remaining = deadline - time.monotonic()
            if remaining <= 0 or self.today_fn() != rendered_for:
                return
            if self._wake.wait(min(self.DATE_CHECK_SECONDS, remaining)):
                return

    def stop(self):
        self._stopping = True
        self._wake.set()


class RateLimiter:
    def __init__(self, min_interval_seconds):
        self.min_interval_seconds = min_interval_seconds
        self._last = 0.0
        self._lock = threading.Lock()

    def allow(self):
        with self._lock:
            now = time.monotonic()
            if self._last and (now - self._last) < self.min_interval_seconds:
                return False
            self._last = now
            return True


class Handler(BaseHTTPRequestHandler):
    server_version = "kitchen-board"
    sys_version = ""
    protocol_version = "HTTP/1.1"

    # Injected by build_server.
    cache = None
    refresh_limiter = None
    cfg = None
    controller = None

    def log_message(self, fmt, *args):
        # The default goes to stderr unformatted; route it through our logger so it
        # lands in the journal under the kitchen tag like everything else.
        log.debug("%s %s", self.address_string(), fmt % args)

    def _send(self, code, body, content_type, extra_headers=None):
        self.send_response(code)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("X-Content-Type-Options", "nosniff")
        for name, value in (extra_headers or {}).items():
            self.send_header(name, value)
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)

    def _send_json(self, code, obj, extra_headers=None):
        body = json.dumps(obj).encode("utf-8")
        headers = {"Cache-Control": "no-store"}
        headers.update(extra_headers or {})
        self._send(code, body, "application/json; charset=utf-8", headers)

    def _read_body(self):
        try:
            length = int(self.headers.get("Content-Length") or 0)
        except ValueError:
            return None
        if length <= 0:
            return {}
        if length > _MAX_BODY_BYTES:
            return None
        raw = self.rfile.read(length)
        try:
            parsed = json.loads(raw.decode("utf-8"))
        except (UnicodeDecodeError, ValueError):
            return None
        return parsed if isinstance(parsed, dict) else None

    def do_GET(self):
        path = self.path.split("?", 1)[0]
        if path == "/health":
            return self._send_json(200, {"status": "ok"})
        if path == "/api/board":
            return self._board()
        if path == "/api/state":
            return self._state()
        if path == "/api/ui":
            return self._ui()
        return self._static(path)

    def do_HEAD(self):
        self.do_GET()

    def do_POST(self):
        path = self.path.split("?", 1)[0]
        if path == "/api/refresh":
            return self._refresh()
        if path == "/api/screen":
            return self._screen()
        if path == "/api/page":
            return self._page()
        return self._send_json(404, {"error": "not found"})

    def _board(self):
        payload = self.cache.current()
        if payload is None:
            # 503 rather than an empty 200, so the frontend keeps what it already has
            # on screen and shows the banner instead of blanking the board.
            return self._send_json(503, {"error": "no board data yet"})
        return self._send_json(200, payload)

    def _state(self):
        if self.controller is None:
            return self._send_json(200, {"screen_on": True, "page": "board",
                                         "revert_to_board": False})
        return self._send_json(200, self.controller.snapshot())

    def _ui(self):
        """
        Settings the browser needs before it can draw.

        Served rather than written into the HTML, so the proxy ports are defined in
        one place only.
        """
        tabs = self.cfg["tabs"]
        return self._send_json(200, {
            "home_url": tabs["home_url"],
            "graphs_url": tabs["graphs_url"],
        })

    def _refresh(self):
        if not self.refresh_limiter.allow():
            return self._send_json(429, {"error": "too many refreshes"},
                                   {"Retry-After": "10"})
        # Run in a thread so the button press returns immediately.
        threading.Thread(target=self.cache.refresh, name="kitchen-manual",
                         daemon=True).start()
        return self._send_json(202, {"status": "refreshing"})

    def _screen(self):
        body = self._read_body()
        if body is None or "on" not in body:
            return self._send_json(400, {"error": "expected {\"on\": bool}"})
        if self.controller is None:
            return self._send_json(501, {"error": "screen control unavailable"})
        self.controller.request_screen(bool(body["on"]))
        return self._send_json(200, self.controller.snapshot())

    def _page(self):
        body = self._read_body()
        if body is None or "page" not in body:
            return self._send_json(400, {"error": "expected {\"page\": str}"})
        page = str(body["page"])[:32]
        if self.controller is not None:
            self.controller.note_page(page)
        return self._send_json(200, {"page": page})

    def _static(self, path):
        if path in ("", "/"):
            path = "/index.html"

        # normpath collapses ".." before the join, and the startswith check catches
        # anything that still escapes (symlinks, odd encodings).
        relative = posixpath.normpath(path).lstrip("/")
        target = os.path.realpath(os.path.join(STATIC_DIR, relative))
        if not target.startswith(os.path.realpath(STATIC_DIR) + os.sep):
            return self._send_json(403, {"error": "forbidden"})
        if not os.path.isfile(target):
            return self._send_json(404, {"error": "not found"})

        content_type, _ = mimetypes.guess_type(target)
        with open(target, "rb") as handle:
            body = handle.read()
        # No caching, so a file changed by Puppet is live after a browser reload.
        return self._send(200, body, content_type or "application/octet-stream",
                          {"Cache-Control": "no-store"})


def build_server(cfg, state, metrics, controller=None):
    cache = BoardCache(cfg, state, metrics)
    loop = RefreshLoop(cache, cfg["refresh"]["interval_minutes"] * 60)

    handler = type("BoundHandler", (Handler,), {
        "cache": cache,
        "refresh_limiter": RateLimiter(
            cfg["refresh"]["min_manual_interval_seconds"]),
        "cfg": cfg,
        "controller": controller,
    })

    address = (cfg["server"]["bind"], cfg["server"]["port"])
    httpd = ThreadingHTTPServer(address, handler)
    httpd.daemon_threads = True
    return httpd, cache, loop


def parse_args(argv=None):
    parser = argparse.ArgumentParser(description="Kitchen board service")
    parser.add_argument("--config", default=config_mod.DEFAULT_PATH)
    parser.add_argument(
        "--dev", action="store_true",
        help="run from the working tree: debug logging, no metrics, no panel "
             "or touchscreen access")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    logging_setup.configure(level=logging.DEBUG if args.dev else logging.INFO)
    cfg = config_mod.load(args.config)

    state = state_mod.State(cfg)
    metrics = NullMetrics() if args.dev else Metrics.from_config(cfg)

    controller = None
    if not args.dev:
        # Imported here so --dev works on a machine with no panel and no
        # touchscreen, which is where the frontend gets developed.
        from .controller import Controller
        controller = Controller(cfg, metrics)

    httpd, cache, loop = build_server(cfg, state, metrics, controller)
    loop.start()
    if controller is not None:
        controller.start()

    log.info("serving on http://%s:%d%s", cfg["server"]["bind"],
             cfg["server"]["port"], " (dev)" if args.dev else "")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        log.info("shutting down")
    finally:
        loop.stop()
        if controller is not None:
            controller.stop()
        httpd.server_close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
