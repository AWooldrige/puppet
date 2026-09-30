#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
import datetime as dt
import unittest

from kitchen import calendar_source as cs


def _tz():
    return cs._tz("Europe/London")


class NodispTests(unittest.TestCase):
    def test_marker_detected_anywhere(self):
        self.assertTrue(cs.has_nodisp("Secret NODISP thing"))
        self.assertTrue(cs.has_nodisp("NODISP"))
        self.assertFalse(cs.has_nodisp("normal event"))
        self.assertFalse(cs.has_nodisp(""))

    def test_nodisp_event_yields_nothing(self):
        event = {
            "summary": "Private NODISP",
            "start": {"date": "2026-07-22"},
            "end": {"date": "2026-07-23"},
        }
        occ = cs.expand_event(event, dt.date(2026, 7, 20),
                              dt.date(2026, 9, 1), _tz())
        self.assertEqual(occ, [])


class ExpansionTests(unittest.TestCase):
    def test_single_all_day(self):
        event = {
            "summary": "Bin day",
            "start": {"date": "2026-07-22"},
            "end": {"date": "2026-07-23"},  # exclusive
        }
        occ = cs.expand_event(event, dt.date(2026, 7, 20),
                              dt.date(2026, 9, 1), _tz())
        self.assertEqual(len(occ), 1)
        self.assertEqual(occ[0].day, dt.date(2026, 7, 22))
        self.assertTrue(occ[0].all_day)
        self.assertFalse(occ[0].multi_day)

    def test_multi_day_all_day_is_single_ranged_entry(self):
        event = {
            "summary": "Holiday",
            "start": {"date": "2026-07-22"},
            "end": {"date": "2026-07-25"},  # exclusive -> 22..24
        }
        occ = cs.expand_event(event, dt.date(2026, 7, 20),
                              dt.date(2026, 9, 1), _tz())
        self.assertEqual(len(occ), 1)
        self.assertEqual(occ[0].day, dt.date(2026, 7, 22))
        self.assertEqual(occ[0].end_day, dt.date(2026, 7, 24))
        self.assertTrue(occ[0].multi_day)

    def test_ongoing_multi_day_clamps_start_to_window(self):
        event = {
            "summary": "Long holiday",
            "start": {"date": "2026-07-10"},
            "end": {"date": "2026-07-25"},  # exclusive -> ends 24th
        }
        occ = cs.expand_event(event, dt.date(2026, 7, 20),
                              dt.date(2026, 9, 1), _tz())
        self.assertEqual(len(occ), 1)
        # Visible start clamped to the window start (today), end kept.
        self.assertEqual(occ[0].day, dt.date(2026, 7, 20))
        self.assertEqual(occ[0].end_day, dt.date(2026, 7, 24))
        self.assertTrue(occ[0].multi_day)

    def test_timed_event_keeps_times_on_correct_day(self):
        event = {
            "summary": "Dentist",
            "start": {"dateTime": "2026-07-22T09:00:00+01:00"},
            "end": {"dateTime": "2026-07-22T09:45:00+01:00"},
        }
        occ = cs.expand_event(event, dt.date(2026, 7, 20),
                              dt.date(2026, 9, 1), _tz())
        self.assertEqual(len(occ), 1)
        self.assertEqual(occ[0].start_time, dt.time(9, 0))
        self.assertEqual(occ[0].end_time, dt.time(9, 45))
        self.assertFalse(occ[0].all_day)

    def test_window_clamps_start_keeps_true_end(self):
        event = {
            "summary": "Long trip",
            "start": {"date": "2026-07-01"},
            "end": {"date": "2026-07-31"},  # exclusive -> ends 30th
        }
        occ = cs.expand_event(event, dt.date(2026, 7, 20),
                              dt.date(2026, 7, 22), _tz())
        self.assertEqual(len(occ), 1)
        self.assertEqual(occ[0].day, dt.date(2026, 7, 20))
        self.assertEqual(occ[0].end_day, dt.date(2026, 7, 30))

    def test_normalise_sorts_all_day_before_timed(self):
        raw = [
            {"summary": "Timed", "start": {"dateTime": "2026-07-22T09:00:00+01:00"},
             "end": {"dateTime": "2026-07-22T10:00:00+01:00"}},
            {"summary": "Allday", "start": {"date": "2026-07-22"},
             "end": {"date": "2026-07-23"}},
        ]
        occ = cs.normalise_events(raw, dt.date(2026, 7, 20),
                                  dt.date(2026, 9, 1), _tz())
        self.assertEqual(occ[0].title, "Allday")
        self.assertEqual(occ[1].title, "Timed")


if __name__ == "__main__":
    unittest.main()
