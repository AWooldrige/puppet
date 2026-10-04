#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
import json
import os
import tempfile
import time
import unittest
from unittest import mock

from kitchen import bank_holidays

from . import support

GOV_UK = {
    "england-and-wales": {"division": "england-and-wales", "events": [
        {"title": "Summer bank holiday", "date": "2026-08-31", "notes": "",
         "bunting": True},
    ]},
    "scotland": {"division": "scotland", "events": [
        {"title": "St Andrew\u2019s Day", "date": "2026-11-30", "notes": "",
         "bunting": True},
    ]},
}


class FakeResponse:
    def raise_for_status(self):
        pass

    def json(self):
        return GOV_UK


class BankHolidayTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.cfg = support.make_config(self.tmp.name)
        self.cache = os.path.join(self.tmp.name, "bank_holidays_cache.json")

    def write_cache(self, holidays, age_hours):
        with open(self.cache, "w") as handle:
            json.dump({"ts": time.time() - age_hours * 3600,
                       "holidays": holidays}, handle)

    def test_only_the_configured_division_is_used(self):
        self.assertEqual(bank_holidays.parse(GOV_UK, "england-and-wales"),
                         {"2026-08-31": "Summer bank holiday"})

    def test_a_fetch_is_cached(self):
        import requests
        with mock.patch.object(requests, "get", return_value=FakeResponse()):
            self.assertIn("2026-08-31", bank_holidays.fetch(self.cfg))
        with open(self.cache) as handle:
            self.assertIn("2026-08-31", json.load(handle)["holidays"])

    def test_a_fresh_cache_is_used_without_fetching(self):
        import requests
        self.write_cache({"2026-01-01": "New Year\u2019s Day"}, age_hours=1)
        with mock.patch.object(requests, "get", side_effect=AssertionError):
            self.assertEqual(bank_holidays.fetch(self.cfg),
                             {"2026-01-01": "New Year\u2019s Day"})

    def test_a_failed_fetch_falls_back_to_an_old_cache(self):
        self.write_cache({"2026-01-01": "New Year\u2019s Day"}, age_hours=24 * 90)
        self.assertEqual(bank_holidays.fetch(self.cfg),
                         {"2026-01-01": "New Year\u2019s Day"})

    def test_a_failed_fetch_with_no_cache_is_no_holidays(self):
        self.assertEqual(bank_holidays.fetch(self.cfg), {})


if __name__ == "__main__":
    unittest.main()
