#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
"""
Line protocol formatting, and which fields the board emits.

The field names are what the Grafana panels are built on, so they are pinned here:
renaming one should break a test, not a dashboard.
"""

import datetime as dt
import tempfile
import unittest
from unittest import mock

from kitchen import board as board_mod
from kitchen import calendar_source
from kitchen import controller as controller_mod
from kitchen import state as state_mod
from kitchen.metrics import Metrics, NullMetrics

from . import support
from .test_board import NOW, RAW_EVENTS, WEATHER
from .test_controller import FakeBacklight


class RecordingMetrics(Metrics):
    """Captures sends instead of putting them on the wire."""

    def __init__(self):
        super().__init__(enabled=True, measurement="kitchen")
        self.sent = []

    def send(self, field, value, tags=None):
        self.sent.append((field, value, tags))

    def fields(self):
        return {field for field, _, _ in self.sent}


class LineProtocolTests(unittest.TestCase):
    def setUp(self):
        self.metrics = Metrics(measurement="kitchen")

    def test_measurement_defaults_to_kitchen(self):
        self.assertEqual(Metrics().measurement, "kitchen")

    def test_plain_field(self):
        self.assertEqual(self.metrics._line("wifi_percent", 90, None),
                         "kitchen wifi_percent=90")

    def test_tags_are_sorted_and_escaped(self):
        line = self.metrics._line("tab_revert", 1,
                                  {"reason": "120s idle", "from": "home"})
        # Sorted by key, and the space in the value is escaped.
        self.assertEqual(line,
                         "kitchen,from=home,reason=120s\\ idle tab_revert=1")

    def test_booleans_become_numbers(self):
        self.assertEqual(self.metrics._line("screen_on", True, None),
                         "kitchen screen_on=1")
        self.assertEqual(self.metrics._line("screen_on", False, None),
                         "kitchen screen_on=0")

    def test_from_config_reads_the_metrics_section(self):
        with tempfile.TemporaryDirectory() as tmp:
            cfg = support.make_config(tmp)
            metrics = Metrics.from_config(cfg)
        self.assertEqual(metrics.measurement, "kitchen")
        self.assertEqual(metrics.port, 8094)
        # The fixture has metrics disabled; the real template enables them.
        self.assertFalse(metrics.enabled)

    def test_disabled_metrics_send_nothing(self):
        sock_calls = []
        with mock.patch("socket.socket",
                        side_effect=lambda *a, **k: sock_calls.append(a)):
            NullMetrics().send("anything", 1)
        self.assertEqual(sock_calls, [])


class BoardMetricsTests(unittest.TestCase):
    """The board refresh path emits the calendar, weather and wifi series."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.cfg = support.make_config(self.tmp.name)
        self.state = state_mod.State(self.cfg)
        self.metrics = RecordingMetrics()

    def build(self):
        tzinfo = calendar_source._tz("Europe/London")
        occurrences = calendar_source.normalise_events(
            RAW_EVENTS, NOW.date(), NOW.date() + dt.timedelta(days=60), tzinfo)
        with mock.patch.object(calendar_source, "fetch_occurrences",
                               return_value=occurrences), \
             mock.patch.object(board_mod.weather_mod, "fetch_weather",
                               return_value=WEATHER), \
             mock.patch.object(board_mod, "check_upstream", return_value=True):
            return board_mod.build(self.cfg, self.state, self.metrics, now=NOW)

    def test_emits_the_expected_fields(self):
        self.build()
        for field in ("calendar_ok", "upstream_ok", "events_shown",
                      "calendar_fetch_seconds", "weather_fetch_seconds"):
            self.assertIn(field, self.metrics.fields())

    def test_event_count_is_the_value_sent(self):
        payload = self.build()
        sent = dict((field, value) for field, value, _ in self.metrics.sent)
        self.assertEqual(sent["events_shown"], payload["event_count"])

    def test_a_failed_calendar_is_reported_as_zero(self):
        with mock.patch.object(calendar_source, "fetch_occurrences",
                               side_effect=RuntimeError("boom")), \
             mock.patch.object(board_mod.weather_mod, "fetch_weather",
                               return_value=None), \
             mock.patch.object(board_mod, "check_upstream", return_value=False):
            board_mod.build(self.cfg, self.state, self.metrics, now=NOW)
        sent = dict((field, value) for field, value, _ in self.metrics.sent)
        self.assertEqual(sent["calendar_ok"], 0)
        self.assertEqual(sent["upstream_ok"], 0)
        self.assertEqual(sent["calendar_load_error"], 1)


class ControllerMetricsTests(unittest.TestCase):
    """Screen state, tab switches and reverts."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        cfg = support.make_config(self.tmp.name)
        cfg["activity"]["device"] = "/nonexistent/kitchen-touch"
        self.clock = dt.datetime(2026, 7, 22, 12, 0,
                                 tzinfo=calendar_source._tz("Europe/London"))
        self.metrics = RecordingMetrics()
        self.controller = controller_mod.Controller(
            cfg, self.metrics, backlight=FakeBacklight(),
            now_fn=lambda: self.clock)

    def test_screen_request_and_state_are_emitted(self):
        self.controller.request_screen(False)
        sent = dict((field, value) for field, value, _ in self.metrics.sent)
        self.assertEqual(sent["screen_request"], 0)
        self.assertEqual(sent["screen_on"], 0)

    def test_tab_switch_is_tagged_with_the_page(self):
        self.controller.note_page("graphs")
        switches = [entry for entry in self.metrics.sent
                    if entry[0] == "tab_switch"]
        self.assertEqual(len(switches), 1)
        self.assertEqual(switches[0][2], {"page": "graphs"})

    def test_revert_is_tagged_with_the_reason(self):
        self.controller.note_page("home")
        self.clock = self.clock + dt.timedelta(seconds=200)
        self.controller.tick()
        reverts = [entry for entry in self.metrics.sent
                   if entry[0] == "tab_revert"]
        self.assertEqual(len(reverts), 1)
        self.assertEqual(reverts[0][2]["from"], "home")
        self.assertEqual(reverts[0][2]["reason"], "120s idle")

    def test_wake_revert_records_a_different_reason(self):
        self.controller.note_page("home")
        self.controller.request_screen(False)
        self.clock = self.clock + dt.timedelta(minutes=10)
        self.controller.tick()
        self.controller.request_screen(True)
        reverts = [entry for entry in self.metrics.sent
                   if entry[0] == "tab_revert"]
        self.assertEqual(reverts[-1][2]["reason"], "woke")

    def test_heartbeat_emits_the_state_series(self):
        self.controller.heartbeat()
        for field in ("screen_on", "idle_seconds", "touch_available",
                      "backlight_available"):
            self.assertIn(field, self.metrics.fields())


if __name__ == "__main__":
    unittest.main()
