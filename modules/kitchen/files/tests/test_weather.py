#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
import unittest

from kitchen import weather


class WeatherCodeTests(unittest.TestCase):
    def test_clear(self):
        self.assertEqual(weather.describe(0), "Clear")

    def test_rain_family(self):
        self.assertEqual(weather.describe(61), "Rain")
        self.assertEqual(weather.describe(65), "Rain")

    def test_snow_family(self):
        self.assertEqual(weather.describe(71), "Snow")
        self.assertEqual(weather.describe(75), "Snow")

    def test_storm(self):
        self.assertEqual(weather.describe(95), "Storms")

    def test_unknown_code_is_mixed(self):
        self.assertEqual(weather.describe(999), "Mixed")


class UvCategoryTests(unittest.TestCase):
    def test_bands(self):
        self.assertEqual(weather.uv_category(0), "Low")
        self.assertEqual(weather.uv_category(2), "Low")
        self.assertEqual(weather.uv_category(3), "Moderate")
        self.assertEqual(weather.uv_category(5), "Moderate")
        self.assertEqual(weather.uv_category(6), "High")
        self.assertEqual(weather.uv_category(8), "Very High")
        self.assertEqual(weather.uv_category(11), "Extreme")


if __name__ == "__main__":
    unittest.main()
