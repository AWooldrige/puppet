#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
"""
The screen schedule and the tab-revert decision.

All pure functions with an injected clock, so both schedule boundaries, the BST/GMT
change and the overnight hold are exercised without waiting for 21:00.
"""

import datetime as dt
import unittest
from zoneinfo import ZoneInfo

from kitchen import scheduler


LONDON = ZoneInfo("Europe/London")
ON_HOUR = 6
OFF_HOUR = 21
HOLD_MINUTES = 5
REVERT_SECONDS = 120


def at(year, month, day, hour, minute=0):
    return dt.datetime(year, month, day, hour, minute, tzinfo=LONDON)


def decide(now, last_activity=None, manual_off_at=None,
           on_hour=ON_HOUR, off_hour=OFF_HOUR):
    return scheduler.screen_should_be_on(
        now, last_activity, manual_off_at, on_hour, off_hour, HOLD_MINUTES)


class ScheduledHoursTests(unittest.TestCase):
    def test_morning_boundary(self):
        # 05:59 is still night, 06:00 is day.
        self.assertFalse(
            scheduler.in_scheduled_hours(at(2026, 7, 22, 5, 59), ON_HOUR, OFF_HOUR))
        self.assertTrue(
            scheduler.in_scheduled_hours(at(2026, 7, 22, 6, 0), ON_HOUR, OFF_HOUR))

    def test_evening_boundary(self):
        # 20:59 is still day, 21:00 is night.
        self.assertTrue(
            scheduler.in_scheduled_hours(at(2026, 7, 22, 20, 59), ON_HOUR, OFF_HOUR))
        self.assertFalse(
            scheduler.in_scheduled_hours(at(2026, 7, 22, 21, 0), ON_HOUR, OFF_HOUR))


class DaylightSavingTests(unittest.TestCase):
    """The boundary is wall-clock, not UTC, in both directions."""

    def test_bst_start_keeps_0600_local(self):
        # 2026-03-29: clocks go forward at 01:00 GMT. 06:00 local is 05:00 UTC.
        morning = at(2026, 3, 29, 6, 0)
        self.assertEqual(morning.utcoffset(), dt.timedelta(hours=1))
        self.assertTrue(decide(morning))
        self.assertFalse(decide(at(2026, 3, 29, 5, 30)))

    def test_gmt_return_keeps_0600_local(self):
        # 2026-10-25: clocks go back. 06:00 local is 06:00 UTC.
        morning = at(2026, 10, 25, 6, 0)
        self.assertEqual(morning.utcoffset(), dt.timedelta(0))
        self.assertTrue(decide(morning))
        self.assertFalse(decide(at(2026, 10, 25, 5, 30)))

    def test_evening_boundary_across_the_change(self):
        for day in (dt.date(2026, 3, 29), dt.date(2026, 10, 25)):
            with self.subTest(day=day):
                self.assertTrue(decide(at(day.year, day.month, day.day, 20, 59)))
                self.assertFalse(decide(at(day.year, day.month, day.day, 21, 0)))


class DaytimeTests(unittest.TestCase):
    def test_on_during_the_day_with_no_activity_at_all(self):
        self.assertTrue(decide(at(2026, 7, 22, 12, 0)))

    def test_manual_off_holds_during_the_day(self):
        now = at(2026, 7, 22, 12, 0)
        self.assertFalse(decide(now, manual_off_at=at(2026, 7, 22, 11, 59)))

    def test_a_touch_after_a_manual_off_wakes_it(self):
        now = at(2026, 7, 22, 12, 0)
        self.assertTrue(decide(
            now,
            manual_off_at=at(2026, 7, 22, 11, 50),
            last_activity=at(2026, 7, 22, 11, 55)))

    def test_a_touch_before_a_manual_off_does_not_wake_it(self):
        now = at(2026, 7, 22, 12, 0)
        self.assertFalse(decide(
            now,
            manual_off_at=at(2026, 7, 22, 11, 55),
            last_activity=at(2026, 7, 22, 11, 50)))


class OvernightTests(unittest.TestCase):
    def test_off_overnight_with_no_activity(self):
        self.assertFalse(decide(at(2026, 7, 22, 3, 0)))

    def test_off_overnight_when_activity_is_stale(self):
        now = at(2026, 7, 22, 3, 0)
        self.assertFalse(decide(now, last_activity=at(2026, 7, 21, 22, 0)))

    def test_a_touch_wakes_it_overnight(self):
        now = at(2026, 7, 22, 3, 0)
        self.assertTrue(decide(now, last_activity=at(2026, 7, 22, 2, 59)))

    def test_the_wake_holds_for_the_configured_minutes(self):
        woken = at(2026, 7, 22, 3, 0)
        # Just inside the hold.
        self.assertTrue(decide(
            woken + dt.timedelta(minutes=HOLD_MINUTES) - dt.timedelta(seconds=1),
            last_activity=woken))
        # And just outside it.
        self.assertFalse(decide(
            woken + dt.timedelta(minutes=HOLD_MINUTES),
            last_activity=woken))

    def test_the_hold_extends_with_continued_use(self):
        # Each touch restarts the hold, so somebody actually using it at 3am does
        # not get the panel blanked under their hand.
        first = at(2026, 7, 22, 3, 0)
        later = first + dt.timedelta(minutes=4)
        self.assertTrue(decide(later + dt.timedelta(minutes=4),
                               last_activity=later))

    def test_2059_to_2100_blanks_but_a_touch_re_wakes(self):
        # The documented behaviour: 21:00 blanks mid-interaction.
        activity = at(2026, 7, 22, 20, 58)
        self.assertTrue(decide(at(2026, 7, 22, 20, 59), last_activity=activity))
        self.assertFalse(decide(at(2026, 7, 22, 21, 4), last_activity=activity))
        # ...and the next touch brings it straight back.
        self.assertTrue(decide(at(2026, 7, 22, 21, 5),
                               last_activity=at(2026, 7, 22, 21, 5)))

    def test_manual_off_overnight_beats_a_recent_touch_before_it(self):
        now = at(2026, 7, 22, 3, 0)
        self.assertFalse(decide(
            now,
            last_activity=at(2026, 7, 22, 2, 58),
            manual_off_at=at(2026, 7, 22, 2, 59)))


class RevertTests(unittest.TestCase):
    NOW = at(2026, 7, 22, 12, 0)

    def revert(self, page, last_activity):
        return scheduler.should_revert_to_board(
            page, self.NOW, last_activity, REVERT_SECONDS)

    def test_board_never_reverts_to_itself(self):
        self.assertFalse(self.revert(
            "board", self.NOW - dt.timedelta(hours=3)))

    def test_recent_activity_keeps_the_tab(self):
        self.assertFalse(self.revert(
            "home", self.NOW - dt.timedelta(seconds=REVERT_SECONDS - 1)))

    def test_idle_at_exactly_the_threshold_reverts(self):
        self.assertTrue(self.revert(
            "home", self.NOW - dt.timedelta(seconds=REVERT_SECONDS)))

    def test_long_idle_reverts(self):
        self.assertTrue(self.revert(
            "graphs", self.NOW - dt.timedelta(minutes=30)))

    def test_no_activity_recorded_reverts(self):
        self.assertTrue(self.revert("graphs", None))


class SecondsSinceTests(unittest.TestCase):
    def test_none_is_none(self):
        self.assertIsNone(scheduler.seconds_since(at(2026, 7, 22, 12), None))

    def test_positive_elapsed(self):
        self.assertEqual(
            scheduler.seconds_since(at(2026, 7, 22, 12, 2),
                                    at(2026, 7, 22, 12, 0)),
            120.0)


if __name__ == "__main__":
    unittest.main()
