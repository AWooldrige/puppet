#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
import datetime as dt
import json
import os
import tempfile
import unittest
from unittest import mock

from kitchen import envelopes

from . import support


def summary(generated_at="2026-08-23T20:14:05", schema=1):
    envelope = {"name": "Food", "frequency": "Monthly", "balance": 300.0,
                "monthly_budget": 600.0, "pct_remaining": 0.5, "total_spend": 40.0,
                "total_receive": 0, "transactions": []}
    return {"schema": schema, "generated_at": generated_at,
            "budget_start": "2026-08-18", "budget_end": "2026-09-18",
            "key": [envelope], "longer_term": []}


class FakeResponse:
    def __init__(self, data, status=200):
        self.data = data
        self.status = status

    def raise_for_status(self):
        if self.status >= 400:
            raise RuntimeError(self.status)

    def json(self):
        return self.data


class RecordingMetrics:
    def __init__(self):
        self.sent = {}

    def send(self, field, value, tags=None):
        self.sent[field] = value


class EnvelopeTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.cfg = support.make_config(self.tmp.name)

    def fetch(self, response):
        import requests
        metrics = RecordingMetrics()
        with mock.patch.object(requests, "get", return_value=response):
            ok = envelopes.refresh(self.cfg, metrics)
        return ok, metrics.sent

    def test_nothing_fetched_yet_is_none(self):
        self.assertIsNone(envelopes.current(self.cfg))

    def test_a_good_fetch_is_kept_and_reported(self):
        ok, sent = self.fetch(FakeResponse(summary()))
        self.assertTrue(ok)
        self.assertEqual(sent["envelopes_ok"], 1)
        self.assertIn("envelopes_age_days", sent)
        kept = envelopes.current(self.cfg, today=dt.date(2026, 8, 27))
        self.assertEqual(kept["key"][0]["name"], "Food")
        self.assertEqual(kept["age_days"], 4)
        self.assertFalse(kept["stale"])

    def test_a_failed_fetch_keeps_the_last_good_copy(self):
        self.fetch(FakeResponse(summary()))
        ok, sent = self.fetch(FakeResponse({}, status=502))
        self.assertFalse(ok)
        self.assertEqual(sent["envelopes_ok"], 0)
        self.assertIsNotNone(envelopes.current(self.cfg))

    def test_an_unknown_schema_is_refused_and_not_kept(self):
        ok, _ = self.fetch(FakeResponse(summary(schema=2)))
        self.assertFalse(ok)
        self.assertIsNone(envelopes.current(self.cfg))

    def test_an_envelope_missing_a_field_is_refused(self):
        bad = summary()
        del bad["key"][0]["pct_remaining"]
        self.assertFalse(self.fetch(FakeResponse(bad))[0])

    def test_unreachable_proxy_fails_soft(self):
        self.assertFalse(envelopes.refresh(self.cfg))

    def test_old_data_is_flagged_stale(self):
        self.fetch(FakeResponse(summary()))
        kept = envelopes.current(self.cfg, today=dt.date(2026, 9, 2))
        self.assertEqual(kept["age_days"], 10)
        self.assertTrue(kept["stale"])

    def test_no_partial_file_is_left_behind(self):
        self.fetch(FakeResponse(summary()))
        self.assertEqual(os.listdir(self.tmp.name), ["envelopes_last_good.json"])


if __name__ == "__main__":
    unittest.main()
