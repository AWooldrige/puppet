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
    "event_count",
    "today.date",
    "today.date_text",
    "today.weekday_text",
    "today.events",
    "today.event_count",
    "today.next_event",
    "sections",
    "weather.available",
    "weather.summary_text",
    "weather.today",
    "weather.days",
    "status.updated_text",
    "status.next_refresh_text",
    "status.wifi_percent",
    "status.load_average",
    "health.ok",
    "health.stale",
    "health.from_cache",
    "health.calendar_ok",
    "health.weather_ok",
    "health.upstream_ok",
    "health.messages",
]

EVENT_KEYS = [
    "id", "title", "day", "day_text", "weekday_text", "end_day", "all_day",
    "multi_day", "start_time", "end_time", "time_text", "location", "is_today",
]

WEATHER_DAY_KEYS = [
    "date", "description", "temp_max", "temp_min", "uv_max", "precip_chance",
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
    support.raw_all_day("Much later", "2026-09-01", "2026-09-02"),
]

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
              now=NOW):
        tzinfo = calendar_source._tz("Europe/London")
        occurrences = calendar_source.normalise_events(
            raw_events, now.date(),
            now.date() + dt.timedelta(days=self.cfg["calendar"]["lookahead_days"]),
            tzinfo)
        with mock.patch.object(calendar_source, "fetch_occurrences",
                               return_value=occurrences), \
             mock.patch.object(board_mod.weather_mod, "fetch_weather",
                               return_value=weather), \
             mock.patch.object(board_mod, "check_upstream",
                               return_value=upstream):
            return board_mod.build(self.cfg, self.state, now=now)


class PayloadAssemblyTests(BoardTestCase):
    def test_events_are_grouped_into_ordered_sections(self):
        payload = self.build()
        names = [section["name"] for section in payload["sections"]]
        self.assertEqual(names, ["This week", "This weekend", "Later"])

    def test_nodisp_events_are_dropped(self):
        payload = self.build()
        titles = [
            event["title"]
            for section in payload["sections"]
            for event in section["events"]
        ]
        self.assertNotIn("Private NODISP", titles)
        self.assertIn("Bin day", titles)

    def test_today_block_only_contains_today(self):
        payload = self.build()
        self.assertEqual(payload["today"]["date"], "2026-07-22")
        self.assertEqual(
            sorted(event["title"] for event in payload["today"]["events"]),
            ["Dentist", "Standup"])
        self.assertEqual(payload["today"]["event_count"], 2)

    def test_next_event_skips_one_already_finished(self):
        # At 08:30 the 07:00 standup is done, so the dentist is next.
        payload = self.build()
        self.assertEqual(payload["today"]["next_event"]["title"], "Dentist")

    def test_next_event_is_none_when_nothing_left_today(self):
        payload = self.build(now=support.london_now(2026, 7, 22, hour=23))
        self.assertIsNone(payload["today"]["next_event"])

    def test_multi_day_event_gets_a_range_label(self):
        payload = self.build()
        holiday = self._find(payload, "Holiday")
        self.assertTrue(holiday["multi_day"])
        self.assertEqual(holiday["end_day"], "2026-07-27")
        self.assertEqual(holiday["time_text"], "\u2192 27 Jul")

    def test_timed_event_gets_a_time_range_label(self):
        payload = self.build()
        self.assertEqual(self._find(payload, "Dentist")["time_text"],
                         "09:00\u201309:45")

    def test_all_day_event_is_labelled_all_day(self):
        payload = self.build()
        self.assertEqual(self._find(payload, "Bin day")["time_text"], "All day")

    def test_location_is_carried_through(self):
        payload = self.build()
        self.assertEqual(self._find(payload, "Dentist")["location"],
                         "High Street")

    def test_weather_days_are_passed_through(self):
        payload = self.build()
        self.assertTrue(payload["weather"]["available"])
        self.assertEqual(len(payload["weather"]["days"]), 3)

    def test_missing_weather_fails_soft(self):
        payload = self.build(weather=None)
        self.assertFalse(payload["weather"]["available"])
        self.assertFalse(payload["health"]["weather_ok"])
        self.assertIn("UV --", payload["weather"]["summary_text"])
        # The calendar is the point of the board; it must survive.
        self.assertTrue(payload["health"]["calendar_ok"])
        self.assertTrue(payload["sections"])

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
             mock.patch.object(board_mod, "check_upstream", return_value=True):
            payload = board_mod.build(self.cfg, self.state, now=NOW)
        self.assertFalse(payload["health"]["calendar_ok"])
        self.assertEqual(payload["sections"], [])
        self.assertIn("Cannot reach Google Calendar",
                      payload["health"]["messages"])

    def test_payload_is_json_serialisable(self):
        json.dumps(self.build())

    def _find(self, payload, title):
        for section in payload["sections"]:
            for event in section["events"]:
                if event["title"] == title:
                    return event
        raise AssertionError(f"{title} not in payload")


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
        self.assertTrue(cached["sections"])

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

    def test_status_is_refreshed_even_on_a_cached_payload(self):
        payload = self.build()
        self.state.save_success(payload)
        later = dt.datetime.now() + dt.timedelta(minutes=90)
        with mock.patch.object(board_mod, "check_upstream", return_value=True):
            cached = board_mod.stale_payload(self.cfg, self.state, now=later)
        self.assertEqual(cached["status"]["updated_text"],
                         later.strftime("%H:%M"))


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

    def test_every_event_has_every_event_key(self):
        payload = self.build()
        events = [
            event
            for section in payload["sections"]
            for event in section["events"]
        ]
        self.assertTrue(events)
        for event in events + payload["today"]["events"]:
            for key in EVENT_KEYS:
                self.assertIn(key, event, f"event missing {key}: {event}")

    def test_every_weather_day_has_every_key(self):
        payload = self.build()
        for day in payload["weather"]["days"]:
            for key in WEATHER_DAY_KEYS:
                self.assertIn(key, day)


if __name__ == "__main__":
    unittest.main()
