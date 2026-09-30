#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
import unittest
from unittest import mock

from kitchen import status


SAMPLE = """Inter-| sta-|   Quality        |   Discarded packets               | Missed | WE
 face | tus | link level noise |  nwid  crypt   frag  retry   misc | beacon | 22
 wlan0: 0000   63.  -47.  -256        0      0      0      0      0        0
"""

NO_WIFI = """Inter-| sta-|   Quality        |   Discarded packets               | Missed | WE
 face | tus | link level noise |  nwid  crypt   frag  retry   misc | beacon | 22
"""


class WifiParseTests(unittest.TestCase):
    def test_parse_percent(self):
        # 63/70 -> 90%
        self.assertEqual(status.parse_wifi_percent(SAMPLE), 90)

    def test_named_interface(self):
        self.assertEqual(status.parse_wifi_percent(SAMPLE, "wlan0"), 90)

    def test_missing_interface_returns_none(self):
        self.assertIsNone(status.parse_wifi_percent(SAMPLE, "wlan1"))

    def test_no_wireless_returns_none(self):
        self.assertIsNone(status.parse_wifi_percent(NO_WIFI))

    def test_full_quality_caps_at_100(self):
        text = SAMPLE.replace("63.", "70.")
        self.assertEqual(status.parse_wifi_percent(text), 100)


class LoadAverageTests(unittest.TestCase):
    def test_rounds_to_one_decimal_place(self):
        with mock.patch.object(status.os, "getloadavg",
                                return_value=(0.5432, 0.61, 0.70)):
            self.assertEqual(status.load_average(), 0.5)

    def test_unavailable_returns_none(self):
        with mock.patch.object(status.os, "getloadavg",
                                side_effect=OSError):
            self.assertIsNone(status.load_average())


if __name__ == "__main__":
    unittest.main()
