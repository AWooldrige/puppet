#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
"""
The controller's stateful behaviour, driven by an injected clock.

The decisions themselves live in test_scheduler.py; this covers the wiring: latching
the revert request, clearing it when the shell reports back, and only touching the
backlight when the state actually changes.
"""

import datetime as dt
import tempfile
import unittest
from zoneinfo import ZoneInfo

from kitchen import controller as controller_mod
from kitchen.metrics import NullMetrics

from . import support


LONDON = ZoneInfo("Europe/London")


def at(hour, minute=0, day=22):
    return dt.datetime(2026, 7, day, hour, minute, tzinfo=LONDON)


class FakeBacklight:
    """Records what it was asked to do, so we can assert on the churn."""

    def __init__(self, available=True):
        self.available = available
        self.calls = []
        self.state = True

    def set_on(self, on):
        self.calls.append(on)
        self.state = on
        return True

    def is_on(self):
        return self.state


class ControllerTestCase(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.cfg = support.make_config(self.tmp.name)
        # A device that will never exist, so the watcher thread stays idle. The
        # controller is never started in these tests anyway - tick() is called
        # directly, which is the point of keeping it a method.
        self.cfg["activity"]["device"] = "/nonexistent/kitchen-touch"
        self.clock = at(12, 0)
        self.backlight = FakeBacklight()
        self.controller = controller_mod.Controller(
            self.cfg, NullMetrics(), backlight=self.backlight,
            now_fn=lambda: self.clock)

    def advance(self, **kwargs):
        self.clock = self.clock + dt.timedelta(**kwargs)


class ScreenStateTests(ControllerTestCase):
    def test_starts_assuming_the_panel_is_lit(self):
        # raspi::touchdisplay's udev rule unblanks at boot, so that is the
        # starting assumption and there should be no write on the first tick.
        self.assertTrue(self.controller.snapshot()["screen_on"])
        self.controller.tick()
        self.assertEqual(self.backlight.calls, [])

    def test_manual_off_blanks_immediately(self):
        self.controller.request_screen(False)
        self.assertFalse(self.controller.snapshot()["screen_on"])
        self.assertEqual(self.backlight.calls, [False])

    def test_a_touch_after_manual_off_wakes_it(self):
        self.controller.request_screen(False)
        self.advance(seconds=30)
        self.controller.note_activity()
        self.controller.tick()
        self.assertTrue(self.controller.snapshot()["screen_on"])
        self.assertEqual(self.backlight.calls, [False, True])

    def test_no_repeated_writes_while_the_state_is_unchanged(self):
        self.controller.request_screen(False)
        for _ in range(5):
            self.advance(seconds=1)
            self.controller.tick()
        self.assertEqual(self.backlight.calls, [False])

    def test_overnight_blanking_and_the_hold(self):
        self.clock = at(20, 59)
        self.controller.note_activity()
        self.controller.tick()
        self.assertTrue(self.controller.snapshot()["screen_on"])

        # Past 21:00 and past the 5 minute hold: dark.
        self.clock = at(21, 5)
        self.controller.tick()
        self.assertFalse(self.controller.snapshot()["screen_on"])

        # A touch brings it back...
        self.controller.note_activity()
        self.controller.tick()
        self.assertTrue(self.controller.snapshot()["screen_on"])

        # ...and it holds for five minutes, then goes dark again.
        self.advance(minutes=5)
        self.controller.tick()
        self.assertFalse(self.controller.snapshot()["screen_on"])

    def test_missing_backlight_is_reported_not_fatal(self):
        self.backlight.available = False
        self.controller.request_screen(False)
        self.assertFalse(self.controller.snapshot()["backlight_available"])


class RevertTests(ControllerTestCase):
    def test_no_revert_while_on_the_board(self):
        self.advance(minutes=30)
        self.controller.tick()
        self.assertFalse(self.controller.snapshot()["revert_to_board"])

    def test_revert_after_the_idle_window_on_another_tab(self):
        self.controller.note_page("home")
        self.assertFalse(self.controller.snapshot()["revert_to_board"])

        self.advance(seconds=119)
        self.controller.tick()
        self.assertFalse(self.controller.snapshot()["revert_to_board"])

        self.advance(seconds=1)
        self.controller.tick()
        self.assertTrue(self.controller.snapshot()["revert_to_board"])

    def test_touching_the_tab_postpones_the_revert(self):
        self.controller.note_page("graphs")
        for _ in range(4):
            self.advance(seconds=60)
            # A touch inside the iframe, seen by the device reader.
            self.controller.note_activity()
            self.controller.tick()
            self.assertFalse(self.controller.snapshot()["revert_to_board"])

    def test_the_request_latches_until_the_shell_reports_back(self):
        self.controller.note_page("home")
        self.advance(seconds=200)
        self.controller.tick()
        self.assertTrue(self.controller.snapshot()["revert_to_board"])

        # A poll the shell missed must not clear it.
        self.controller.tick()
        self.assertTrue(self.controller.snapshot()["revert_to_board"])

        # The shell switching back is what clears it.
        self.controller.note_page("board")
        self.assertFalse(self.controller.snapshot()["revert_to_board"])

    def test_no_revert_requested_while_the_panel_is_dark(self):
        # Dropping the iframe nobody can see is pointless churn, and it would
        # mean the panel wakes having already thrown the tab away for no reason.
        self.controller.note_page("home")
        self.controller.request_screen(False)
        self.advance(seconds=300)
        self.controller.tick()
        snapshot = self.controller.snapshot()
        self.assertFalse(snapshot["screen_on"])
        self.assertFalse(snapshot["revert_to_board"])

    def test_waking_always_ends_up_back_on_the_board(self):
        self.controller.note_page("graphs")
        self.controller.request_screen(False)
        self.advance(minutes=10)
        self.controller.tick()

        # Wake it: the panel comes on, and because the tab has been idle far
        # longer than the window, a revert is requested straight away.
        self.controller.request_screen(True)
        snapshot = self.controller.snapshot()
        self.assertTrue(snapshot["screen_on"])
        self.assertTrue(snapshot["revert_to_board"])


class SnapshotTests(ControllerTestCase):
    def test_snapshot_has_the_keys_the_frontend_reads(self):
        snapshot = self.controller.snapshot()
        for key in ("screen_on", "page", "revert_to_board"):
            self.assertIn(key, snapshot)

    def test_idle_seconds_tracks_the_clock(self):
        self.controller.note_activity()
        self.advance(seconds=42)
        self.assertEqual(self.controller.snapshot()["idle_seconds"], 42.0)

    def test_page_is_reported(self):
        self.controller.note_page("graphs")
        self.assertEqual(self.controller.snapshot()["page"], "graphs")


if __name__ == "__main__":
    unittest.main()
