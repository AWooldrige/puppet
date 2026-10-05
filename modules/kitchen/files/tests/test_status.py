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


MEMINFO = """MemTotal:        3884512 kB
MemFree:          512000 kB
MemAvailable:    1942256 kB
"""


class DeviceParseTests(unittest.TestCase):
    def test_uptime(self):
        self.assertEqual(status.parse_uptime("12345.67 40000.00\n"), 12345)
        self.assertIsNone(status.parse_uptime(None))
        self.assertIsNone(status.parse_uptime(""))

    def test_cpu_temp(self):
        self.assertEqual(status.parse_cpu_temp("51634\n"), 51.6)
        self.assertIsNone(status.parse_cpu_temp(None))
        self.assertIsNone(status.parse_cpu_temp("hot"))

    def test_memory_available(self):
        self.assertEqual(status.parse_memory_available(MEMINFO), 50)
        self.assertIsNone(status.parse_memory_available("MemTotal: 10 kB\n"))
        self.assertIsNone(status.parse_memory_available(None))

    def test_alarm(self):
        self.assertTrue(status.parse_alarm("1\n"))
        self.assertFalse(status.parse_alarm("0\n"))
        self.assertIsNone(status.parse_alarm(None))
        self.assertIsNone(status.parse_alarm("x"))

    def test_under_voltage_without_a_sensor_is_unknown(self):
        self.assertIsNone(status.under_voltage("/nonexistent/hwmon*/alarm"))

    def test_disk_free_is_a_number_of_bytes(self):
        self.assertGreater(status.disk_free_bytes("/"), 0)
        self.assertIsNone(status.disk_free_bytes("/nonexistent/path"))


if __name__ == "__main__":
    unittest.main()
