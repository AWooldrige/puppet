#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
"""
The HTTP surface: routing, the cache, rate limiting and static serving.

Runs a real server on an ephemeral loopback port, because the interesting bugs here
(status codes, traversal, threading) do not show up when the handler is called
directly.
"""

import datetime as dt
import json
import os
import tempfile
import threading
import time
import unittest
import urllib.error
import urllib.request
from unittest import mock

from kitchen import app as app_mod
from kitchen import board as board_mod
from kitchen import state as state_mod
from kitchen.metrics import NullMetrics

from . import support


PAYLOAD = {
    "generated_at": 1.0,
    "event_count": 1,
    "days": [],
    "health": {"ok": True, "stale": False, "from_cache": False,
               "calendar_ok": True, "weather_ok": False, "upstream_ok": True,
               "messages": []},
}


class FakeController:
    def __init__(self):
        self.screen_requests = []
        self.pages = []
        self.activity = 0

    def snapshot(self):
        return {"screen_on": True, "page": "board", "revert_to_board": False}

    def request_screen(self, on):
        self.screen_requests.append(on)

    def note_page(self, page):
        self.pages.append(page)

    def note_activity(self):
        self.activity += 1


class ServerTestCase(unittest.TestCase):
    controller = None

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.cfg = support.make_config(self.tmp.name)
        # Port 0: let the kernel pick, so tests never collide with a real board.
        self.cfg["server"]["port"] = 0
        self.state = state_mod.State(self.cfg)

        self.httpd, self.cache, self.loop = app_mod.build_server(
            self.cfg, self.state, NullMetrics(), self.controller)
        self.addCleanup(self.httpd.server_close)
        self.port = self.httpd.server_address[1]
        # poll_interval also bounds how long shutdown() takes, and the default
        # 0.5s per test dominated the whole suite's runtime.
        self.thread = threading.Thread(
            target=self.httpd.serve_forever, kwargs={'poll_interval': 0.01},
            daemon=True)
        self.thread.start()
        self.addCleanup(self._shutdown)

    def _shutdown(self):
        self.httpd.shutdown()
        self.thread.join(timeout=5)

    def url(self, path):
        return f"http://127.0.0.1:{self.port}{path}"

    def get(self, path):
        try:
            with urllib.request.urlopen(self.url(path), timeout=5) as resp:
                return resp.status, resp.read(), dict(resp.headers)
        except urllib.error.HTTPError as err:
            with err:
                return err.code, err.read(), dict(err.headers)

    def post(self, path, body=None):
        data = json.dumps(body or {}).encode("utf-8")
        request = urllib.request.Request(
            self.url(path), data=data, method="POST",
            headers={"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(request, timeout=5) as resp:
                return resp.status, resp.read()
        except urllib.error.HTTPError as err:
            with err:
                return err.code, err.read()


class RoutingTests(ServerTestCase):
    def test_health_is_ok(self):
        status, body, _ = self.get("/health")
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(body), {"status": "ok"})

    def test_board_is_503_before_any_data(self):
        # Honest failure rather than an empty 200: the frontend keeps what it has.
        status, _, _ = self.get("/api/board")
        self.assertEqual(status, 503)

    def test_board_serves_the_cached_payload(self):
        with mock.patch.object(board_mod, "build", return_value=PAYLOAD):
            self.cache.refresh()
        status, body, headers = self.get("/api/board")
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(body)["event_count"], 1)
        self.assertEqual(headers.get("Cache-Control"), "no-store")

    def test_envelopes_are_503_before_any_summary(self):
        self.assertEqual(self.get("/api/envelopes")[0], 503)

    def test_envelopes_serve_the_kept_summary_with_its_age(self):
        from . import test_envelopes
        with open(os.path.join(self.tmp.name, "envelopes_last_good.json"), "w") as f:
            json.dump(test_envelopes.summary(), f)
        status, body, headers = self.get("/api/envelopes")
        self.assertEqual(status, 200)
        self.assertIn("age_days", json.loads(body))
        self.assertEqual(headers.get("Cache-Control"), "no-store")

    def test_ui_exposes_the_tab_urls(self):
        status, body, _ = self.get("/api/ui")
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(body), {
            "home_url": self.cfg["tabs"]["home_url"],
            "graphs_url": self.cfg["tabs"]["graphs_url"],
        })

    def test_state_without_a_controller_still_answers(self):
        status, body, _ = self.get("/api/state")
        self.assertEqual(status, 200)
        self.assertTrue(json.loads(body)["screen_on"])

    def test_screen_without_a_controller_is_501(self):
        status, _ = self.post("/api/screen", {"on": False})
        self.assertEqual(status, 501)

    def test_unknown_post_is_404(self):
        status, _ = self.post("/api/nope")
        self.assertEqual(status, 404)

    def test_diagnostics_answer_before_any_data(self):
        with mock.patch.object(board_mod, "check_upstream", return_value=False):
            status, body, headers = self.get("/api/diagnostics")
        self.assertEqual(status, 200)
        data = json.loads(body)
        self.assertIsNone(data["board"])
        self.assertIsNone(data["envelopes"])
        self.assertIsNone(data["controller"])
        self.assertIn("under_voltage", data)
        self.assertEqual(headers.get("Cache-Control"), "no-store")

    def test_diagnostics_describe_the_cached_board(self):
        with mock.patch.object(board_mod, "build", return_value=PAYLOAD):
            self.cache.refresh()
        data = json.loads(self.get("/api/diagnostics")[1])
        self.assertEqual(data["board"]["event_count"], 1)
        self.assertTrue(data["board"]["health"]["ok"])
        self.assertRegex(data["board"]["next_refresh_text"], r"\d\d:\d\d")


class DiagnosticsTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.cfg = support.make_config(self.tmp.name)

    def test_updated_and_next_refresh_come_from_the_payload_not_the_clock(self):
        now = support.london_now(2026, 7, 22, hour=12)
        generated = support.london_now(2026, 7, 22, hour=9)
        payload = dict(PAYLOAD, generated_at=generated.timestamp())
        board = app_mod.diagnostics(self.cfg, payload, None, None, now)["board"]
        self.assertEqual(board["updated_text"], "09:00")
        self.assertEqual(board["next_refresh_text"], "09:30")

    def test_a_payload_from_another_day_shows_its_date(self):
        now = support.london_now(2026, 7, 22, hour=12)
        generated = support.london_now(2026, 7, 20, hour=9)
        payload = dict(PAYLOAD, generated_at=generated.timestamp())
        board = app_mod.diagnostics(self.cfg, payload, None, None, now)["board"]
        self.assertEqual(board["updated_text"], "20 Jul 09:00")


class KeepAliveTests(ServerTestCase):
    def test_a_post_body_the_route_ignores_does_not_corrupt_the_next_request(self):
        import http.client
        conn = http.client.HTTPConnection("127.0.0.1", self.port, timeout=5)
        self.addCleanup(conn.close)
        for path in ("/api/lock", "/api/refresh"):
            with mock.patch.object(board_mod, "build", return_value=PAYLOAD):
                conn.request("POST", path, body=b"{}",
                             headers={"Content-Type": "application/json"})
                conn.getresponse().read()
            conn.request("GET", "/health")
            resp = conn.getresponse()
            self.assertEqual(resp.status, 200, path)
            resp.read()


class LockTests(ServerTestCase):
    def locked(self):
        return json.loads(self.get("/api/state")[1])["locked"]

    def test_starts_unlocked_and_locks(self):
        self.assertFalse(self.locked())
        self.assertEqual(self.post("/api/lock")[0], 200)
        self.assertTrue(self.locked())

    def test_the_right_pin_unlocks(self):
        self.post("/api/lock")
        self.assertEqual(self.post("/api/unlock", {"pin": "1234"})[0], 200)
        self.assertFalse(self.locked())

    def test_a_wrong_pin_is_refused_then_throttled(self):
        self.post("/api/lock")
        self.assertEqual(self.post("/api/unlock", {"pin": "0000"})[0], 403)
        self.assertEqual(self.post("/api/unlock", {"pin": "1234"})[0], 429)
        self.assertTrue(self.locked())

    def test_a_malformed_unlock_is_400(self):
        self.post("/api/lock")
        for body in ({}, {"pin": 1234}, {"pin": "1" * 17}):
            self.assertEqual(self.post("/api/unlock", body)[0], 400, body)
        self.assertTrue(self.locked())


class ScreenLockTests(unittest.TestCase):
    def test_the_throttle_expires(self):
        lock = app_mod.ScreenLock("1234", retry_seconds=0.05)
        lock.lock()
        self.assertEqual(lock.unlock("9999"), "wrong")
        self.assertEqual(lock.unlock("1234"), "wait")
        time.sleep(0.06)
        self.assertEqual(lock.unlock("1234"), "ok")
        self.assertFalse(lock.locked)


class RefreshTests(ServerTestCase):
    def test_refresh_is_accepted_then_rate_limited(self):
        with mock.patch.object(board_mod, "build", return_value=PAYLOAD):
            first, _ = self.post("/api/refresh")
            second, body = self.post("/api/refresh")
        self.assertEqual(first, 202)
        self.assertEqual(second, 429)
        self.assertIn("too many", json.loads(body)["error"])


class ScreenControlTests(ServerTestCase):
    controller = None

    def setUp(self):
        self.controller = FakeController()
        super().setUp()

    def test_screen_request_reaches_the_controller(self):
        status, _ = self.post("/api/screen", {"on": False})
        self.assertEqual(status, 200)
        self.assertEqual(self.controller.screen_requests, [False])

    def test_state_carries_the_lock_alongside_the_controller(self):
        self.post("/api/lock")
        state = json.loads(self.get("/api/state")[1])
        self.assertTrue(state["locked"])
        self.assertEqual(state["page"], "board")

    def test_diagnostics_include_the_controller_snapshot(self):
        with mock.patch.object(board_mod, "check_upstream", return_value=False):
            data = json.loads(self.get("/api/diagnostics")[1])
        self.assertEqual(data["controller"]["page"], "board")

    def test_screen_needs_an_on_field(self):
        status, _ = self.post("/api/screen", {"nope": 1})
        self.assertEqual(status, 400)

    def test_page_is_recorded(self):
        self.assertEqual(self.post("/api/page", {"page": "graphs"})[0], 200)
        self.assertEqual(self.controller.pages, ["graphs"])


class StaticTests(ServerTestCase):
    def test_root_serves_the_shell(self):
        status, body, headers = self.get("/")
        self.assertEqual(status, 200)
        self.assertIn(b"<title>Kitchen board</title>", body)
        self.assertTrue(headers["Content-Type"].startswith("text/html"))

    def test_css_and_js_are_served_with_sane_types(self):
        for path, expected in (("/board.css", "text/css"),
                               ("/board.js", "javascript")):
            status, _, headers = self.get(path)
            self.assertEqual(status, 200, path)
            self.assertIn(expected, headers["Content-Type"], path)

    def test_missing_file_is_404(self):
        self.assertEqual(self.get("/nope.html")[0], 404)

    def test_traversal_cannot_escape_the_static_root(self):
        # normpath collapses these before the join, so they resolve inside
        # static/ and simply do not exist - never to /etc/passwd.
        for path in ("/../../../../etc/passwd", "/..%2f..%2fetc/passwd",
                     "/static/../../config.py"):
            status, body, _ = self.get(path)
            self.assertIn(status, (403, 404), path)
            self.assertNotIn(b"root:", body, path)

    def test_package_source_is_not_reachable(self):
        self.assertIn(self.get("/config.py")[0], (403, 404))


class CacheFallbackTests(ServerTestCase):
    def test_failed_refresh_falls_back_to_the_saved_snapshot(self):
        good = dict(PAYLOAD)
        with mock.patch.object(board_mod, "build", return_value=good):
            self.assertTrue(self.cache.refresh())

        broken = json.loads(json.dumps(PAYLOAD))
        broken["health"]["calendar_ok"] = False
        broken["event_count"] = 0
        with mock.patch.object(board_mod, "build", return_value=broken), \
             mock.patch.object(board_mod, "check_upstream", return_value=True):
            self.assertFalse(self.cache.refresh())

        status, body, _ = self.get("/api/board")
        payload = json.loads(body)
        self.assertEqual(status, 200)
        self.assertTrue(payload["health"]["from_cache"])
        # The good event count survived the bad fetch.
        self.assertEqual(payload["event_count"], 1)

    def test_a_raising_build_does_not_take_the_server_down(self):
        with mock.patch.object(board_mod, "build",
                               side_effect=RuntimeError("boom")):
            self.assertFalse(self.cache.refresh())
        self.assertEqual(self.get("/health")[0], 200)


if __name__ == "__main__":
    unittest.main()


class RefreshLoopTests(unittest.TestCase):
    """
    The Pi has no clock battery, so the board can render a date from whenever the
    image was built and only find out seconds later, once chrony steps the clock.
    """

    class FakeCache:
        def __init__(self):
            self.refreshes = 0

        def refresh(self):
            self.refreshes += 1
            return True

    def test_a_date_jump_cuts_the_wait_short(self):
        cache = self.FakeCache()
        dates = iter([dt.date(2026, 7, 27), dt.date(2026, 9, 23)])
        last = [dt.date(2026, 7, 27)]

        def today():
            try:
                last[0] = next(dates)
            except StopIteration:
                pass
            return last[0]

        loop = app_mod.RefreshLoop(cache, interval_seconds=1800, today_fn=today)
        loop.DATE_CHECK_SECONDS = 0.01
        started = time.monotonic()
        loop._wait_until_stale(dt.date(2026, 7, 27))
        self.assertLess(time.monotonic() - started, 5, 'should not wait out the interval')

    def test_the_wait_is_not_cut_short_on_the_same_day(self):
        loop = app_mod.RefreshLoop(self.FakeCache(), interval_seconds=0.05,
                               today_fn=lambda: dt.date(2026, 9, 23))
        loop.DATE_CHECK_SECONDS = 0.01
        started = time.monotonic()
        loop._wait_until_stale(dt.date(2026, 9, 23))
        self.assertGreaterEqual(time.monotonic() - started, 0.05)

    def test_stopping_returns_immediately(self):
        loop = app_mod.RefreshLoop(self.FakeCache(), interval_seconds=1800,
                               today_fn=lambda: dt.date(2026, 9, 23))
        loop.stop()
        started = time.monotonic()
        loop._wait_until_stale(dt.date(2026, 9, 23))
        self.assertLess(time.monotonic() - started, 1)
