#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
"""
Board payload assembly, the stale-cache fallback, and the frontend contract.
"""

import datetime as dt
import json
import tempfile
import unittest
from unittest import mock

from kitchen import board as board_mod
from kitchen import calendar_source
from kitchen import state as state_mod

from . import support


# Every key path static/board.js reads. Add a payload read there, add it here.
FRONTEND_KEY_PATHS = [
    "generated_at",
    "days",
    "health.ok",
    "health.stale",
    "health.from_cache",
    "health.calendar_ok",
    "health.weather_ok",
    "health.upstream_ok",
    "health.messages",
]

DAY_KEYS = [
    "date", "weekday_text", "day_number", "day_text", "is_today", "is_weekend",
    "is_week_start", "bank_holiday", "weather", "events",
]

EVENT_KEYS = [
    "title", "location", "all_day", "multi_day", "continues", "start_time",
    "end_time", "time_text",
]

DAY_WEATHER_KEYS = [
    "description", "temp_max", "temp_min", "precip_chance", "uv_text",
]


def resolve(payload, dotted):
    node = payload
    for part in dotted.split("."):
        assert isinstance(node, dict), f"{dotted}: {part} is not under a dict"
        assert part in node, f"missing payload key: {dotted}"
        node = node[part]
    return node


# Wednesday.
NOW = support.london_now(2026, 7, 22, hour=8, minute=30)

RAW_EVENTS = [
    support.raw_timed("Dentist", "2026-07-22T09:00:00+01:00",
                      "2026-07-22T09:45:00+01:00", location="High Street"),
    support.raw_timed("Standup", "2026-07-22T07:00:00+01:00",
                      "2026-07-22T07:15:00+01:00"),
    support.raw_all_day("Bin day", "2026-07-23", "2026-07-24"),
    support.raw_all_day("Holiday", "2026-07-25", "2026-07-28"),
    support.raw_all_day("Private NODISP", "2026-07-24", "2026-07-25"),
    support.raw_all_day("Much later", "2026-08-20", "2026-08-21"),
    support.raw_all_day("Camping", "2026-07-30", "2026-08-03"),
    support.raw_all_day("Beyond the board", "2026-09-28", "2026-09-29"),
]

HOLIDAYS = {"2026-08-31": "Summer bank holiday", "2026-07-27": "Made-up holiday"}

WEATHER = {
    "description": "Rain",
    "temp_max": 17.6,
    "temp_min": 8.9,
    "uv_max": 3.2,
    "precip_chance": 80,
    "days": [
        {"date": "2026-07-22", "description": "Rain", "temp_max": 17.6,
         "temp_min": 8.9, "uv_max": 3.2, "precip_chance": 80},
        {"date": "2026-07-23", "description": "Clear", "temp_max": 21.0,
         "temp_min": 11.0, "uv_max": 5.0, "precip_chance": 5},
        {"date": "2026-07-24", "description": "Cloudy", "temp_max": 19.0,
         "temp_min": 12.0, "uv_max": 4.0, "precip_chance": 20},
    ],
}


class BoardTestCase(unittest.TestCase):
    """Builds a payload with the network stubbed out at the module boundary."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.cfg = support.make_config(self.tmp.name)
        self.state = state_mod.State(self.cfg)

    def build(self, raw_events=RAW_EVENTS, weather=WEATHER, upstream=True,
              now=NOW, holidays=HOLIDAYS):
        tzinfo = calendar_source._tz("Europe/London")
        occurrences = calendar_source.normalise_events(
            raw_events, now.date(),
            now.date() + dt.timedelta(days=self.cfg["calendar"]["lookahead_days"]),
            tzinfo)
        with mock.patch.object(calendar_source, "fetch_occurrences",
                               return_value=occurrences), \
             mock.patch.object(board_mod.weather_mod, "fetch_weather",
                               return_value=weather), \
             mock.patch.object(board_mod.bank_holidays_mod, "fetch",
                               return_value=holidays), \
             mock.patch.object(board_mod, "check_upstream",
                               return_value=upstream):
            return board_mod.build(self.cfg, self.state, now=now)


class PayloadAssemblyTests(BoardTestCase):
    def day(self, payload, iso):
        return next(d for d in payload["days"] if d["date"] == iso)

    def titles(self, payload, iso):
        return [e["title"] for e in self.day(payload, iso)["events"]]

    def test_every_day_is_present_including_empty_ones(self):
        days = self.build()["days"]
        self.assertEqual(len(days), self.cfg["calendar"]["lookahead_days"])
        self.assertEqual(days[0]["date"], "2026-07-22")
        self.assertEqual(days[-1]["date"], "2026-09-21")
        self.assertEqual(self.titles({"days": days}, "2026-07-29"), [])

    def test_only_today_is_flagged_today(self):
        days = self.build()["days"]
        self.assertEqual([d["date"] for d in days if d["is_today"]], ["2026-07-22"])

    def test_weekends_and_week_starts_are_flagged(self):
        payload = self.build()
        self.assertTrue(self.day(payload, "2026-07-25")["is_weekend"])
        self.assertTrue(self.day(payload, "2026-07-26")["is_weekend"])
        self.assertFalse(self.day(payload, "2026-07-24")["is_weekend"])
        self.assertTrue(self.day(payload, "2026-07-27")["is_week_start"])
        self.assertFalse(self.day(payload, "2026-07-28")["is_week_start"])

    def test_bank_holidays_are_named_on_their_day(self):
        payload = self.build()
        self.assertEqual(self.day(payload, "2026-07-27")["bank_holiday"],
                         "Made-up holiday")
        self.assertIsNone(self.day(payload, "2026-07-28")["bank_holiday"])

    def test_no_bank_holidays_is_fine(self):
        payload = self.build(holidays={})
        self.assertTrue(all(d["bank_holiday"] is None for d in payload["days"]))

    def test_nodisp_events_are_dropped(self):
        payload = self.build()
        self.assertEqual(self.titles(payload, "2026-07-24"), [])
        self.assertEqual(self.titles(payload, "2026-07-23"), ["Bin day"])

    def test_events_past_the_board_are_not_shown(self):
        payload = self.build()
        titles = [e["title"] for d in payload["days"] for e in d["events"]]
        self.assertNotIn("Beyond the board", titles)

    def test_multi_day_event_appears_on_every_day_it_covers(self):
        payload = self.build()
        runs = [(d["date"], e["continues"]) for d in payload["days"]
                for e in d["events"] if e["title"] == "Holiday"]
        self.assertEqual(runs, [("2026-07-25", "first"), ("2026-07-26", "middle"),
                                ("2026-07-27", "last")])

    def test_multi_day_event_crosses_a_month_boundary(self):
        payload = self.build()
        runs = [d["date"] for d in payload["days"]
                for e in d["events"] if e["title"] == "Camping"]
        self.assertEqual(runs, ["2026-07-30", "2026-07-31", "2026-08-01",
                                "2026-08-02"])
        camping = self.day(payload, "2026-08-02")["events"][0]
        self.assertEqual(camping["time_text"], "Thu 30 Jul to Sun 2 Aug")

    def test_event_already_running_is_marked_as_continuing(self):
        raw = [support.raw_all_day("Away", "2026-07-20", "2026-07-24")]
        payload = self.build(raw_events=raw)
        self.assertEqual(self.day(payload, "2026-07-22")["events"][0]["continues"],
                         "middle")

    def test_spans_come_before_timed_events_which_are_in_time_order(self):
        raw = RAW_EVENTS + [support.raw_all_day("Away", "2026-07-20",
                                                "2026-07-24")]
        payload = self.build(raw_events=raw)
        self.assertEqual(self.titles(payload, "2026-07-22"),
                         ["Away", "Standup", "Dentist"])

    def test_timed_event_gets_a_time_range_label(self):
        event = self.day(self.build(), "2026-07-22")["events"][1]
        self.assertEqual(event["title"], "Dentist")
        self.assertEqual(event["time_text"], "09:00 to 09:45")
        self.assertEqual(event["start_time"], "09:00")
        self.assertEqual(event["location"], "High Street")

    def test_all_day_event_is_labelled_all_day(self):
        event = self.day(self.build(), "2026-07-23")["events"][0]
        self.assertEqual(event["time_text"], "All day")
        self.assertIsNone(event["continues"])

    def test_bst_ends_without_shifting_a_day(self):
        now = support.london_now(2026, 10, 23, hour=8)
        raw = [support.raw_timed("Late", "2026-10-25T23:30:00+00:00",
                                 "2026-10-25T23:45:00+00:00")]
        payload = self.build(raw_events=raw, now=now, weather=None)
        self.assertEqual(self.titles(payload, "2026-10-25"), ["Late"])
        self.assertEqual(self.day(payload, "2026-10-25")["events"][0]["start_time"],
                         "23:30")

    def test_forecast_lands_on_the_matching_days_only(self):
        payload = self.build()
        self.assertEqual(self.day(payload, "2026-07-23")["weather"]["description"],
                         "Clear")
        self.assertEqual(self.day(payload, "2026-07-22")["weather"]["uv_text"],
                         "UV 3 Moderate")
        self.assertIsNone(self.day(payload, "2026-07-25")["weather"])

    def test_missing_weather_fails_soft(self):
        payload = self.build(weather=None)
        self.assertTrue(all(d["weather"] is None for d in payload["days"]))
        self.assertFalse(payload["health"]["weather_ok"])
        # The calendar is the point of the board; it must survive.
        self.assertTrue(payload["health"]["calendar_ok"])
        self.assertEqual(self.titles(payload, "2026-07-23"), ["Bin day"])

    def test_event_count_counts_each_event_once(self):
        self.assertEqual(self.build()["event_count"], 6)

    def test_unreachable_upstream_is_not_ok_and_says_why(self):
        payload = self.build(upstream=False)
        self.assertFalse(payload["health"]["upstream_ok"])
        self.assertFalse(payload["health"]["ok"])
        self.assertIn("Cannot reach the home server",
                      payload["health"]["messages"])

    def test_calendar_failure_is_reported_not_raised(self):
        with mock.patch.object(calendar_source, "fetch_occurrences",
                               side_effect=RuntimeError("boom")), \
             mock.patch.object(board_mod.weather_mod, "fetch_weather",
                               return_value=WEATHER), \
             mock.patch.object(board_mod.bank_holidays_mod, "fetch",
                               return_value={}), \
             mock.patch.object(board_mod, "check_upstream", return_value=True):
            payload = board_mod.build(self.cfg, self.state, now=NOW)
        self.assertFalse(payload["health"]["calendar_ok"])
        self.assertTrue(all(not d["events"] for d in payload["days"]))
        self.assertIn("Cannot reach Google Calendar",
                      payload["health"]["messages"])

    def test_payload_is_json_serialisable(self):
        json.dumps(self.build())


class StaleFallbackTests(BoardTestCase):
    def test_no_snapshot_yields_none(self):
        self.assertIsNone(board_mod.stale_payload(self.cfg, self.state))

    def test_snapshot_is_served_with_a_from_cache_flag(self):
        self.state.save_success(self.build())
        with mock.patch.object(board_mod, "check_upstream", return_value=True):
            cached = board_mod.stale_payload(self.cfg, self.state)
        self.assertTrue(cached["health"]["from_cache"])
        self.assertFalse(cached["health"]["ok"])
        # Real events, not an empty board.
        self.assertTrue(any(d["events"] for d in cached["days"]))

    def test_recent_snapshot_is_not_flagged_stale(self):
        self.state.save_success(self.build())
        with mock.patch.object(board_mod, "check_upstream", return_value=True):
            cached = board_mod.stale_payload(self.cfg, self.state)
        self.assertFalse(cached["health"]["stale"])
        self.assertEqual(cached["health"]["messages"], ["Showing saved data"])

    def test_old_snapshot_is_flagged_stale_with_a_banner_message(self):
        self.state.save_success(self.build())
        old = dt.datetime.now() + dt.timedelta(hours=7)
        with mock.patch.object(board_mod, "check_upstream", return_value=True):
            cached = board_mod.stale_payload(self.cfg, self.state, now=old)
        self.assertTrue(cached["health"]["stale"])
        self.assertIn("Calendar may be out of date",
                      cached["health"]["messages"])


class FrontendContractTests(BoardTestCase):
    """The payload must carry every key the frontend reads, always."""

    def test_live_payload_has_every_frontend_key(self):
        payload = self.build()
        for dotted in FRONTEND_KEY_PATHS:
            resolve(payload, dotted)

    def test_degraded_payload_has_every_frontend_key(self):
        # Worst realistic case: nothing worked. The frontend still renders, so
        # every key it reads has to exist.
        with mock.patch.object(calendar_source, "fetch_occurrences",
                               side_effect=RuntimeError("boom")), \
             mock.patch.object(board_mod.weather_mod, "fetch_weather",
                               return_value=None), \
             mock.patch.object(board_mod.bank_holidays_mod, "fetch",
                               return_value={}), \
             mock.patch.object(board_mod, "check_upstream", return_value=False):
            payload = board_mod.build(self.cfg, self.state, now=NOW)
        for dotted in FRONTEND_KEY_PATHS:
            resolve(payload, dotted)

    def test_cached_payload_has_every_frontend_key(self):
        self.state.save_success(self.build())
        with mock.patch.object(board_mod, "check_upstream", return_value=False):
            payload = board_mod.stale_payload(self.cfg, self.state)
        for dotted in FRONTEND_KEY_PATHS:
            resolve(payload, dotted)

    def test_every_day_and_event_has_every_key(self):
        payload = self.build()
        events = []
        for day in payload["days"]:
            for key in DAY_KEYS:
                self.assertIn(key, day, f"day missing {key}: {day}")
            events.extend(day["events"])
            if day["weather"]:
                for key in DAY_WEATHER_KEYS:
                    self.assertIn(key, day["weather"])
        self.assertTrue(events)
        for event in events:
            for key in EVENT_KEYS:
                self.assertIn(key, event, f"event missing {key}: {event}")


if __name__ == "__main__":
    unittest.main()
