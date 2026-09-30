#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
import unittest

from kitchen import config


SAMPLE = """
[calendar]
calendar_ids = ["a@example.com", "b@example.com"]
lookahead_days = 60

[display]
width = 480
height = 800

[server]
listen_port = 8443
"""


class ConfigTests(unittest.TestCase):
    def test_parses_toml(self):
        cfg = config.loads(SAMPLE)
        self.assertEqual(cfg["calendar"]["calendar_ids"],
                         ["a@example.com", "b@example.com"])
        self.assertEqual(cfg["display"]["width"], 480)
        self.assertEqual(cfg["server"]["listen_port"], 8443)

    def test_missing_file_raises(self):
        with self.assertRaises(FileNotFoundError):
            config.load("/nonexistent/kitchen/config.toml")


if __name__ == "__main__":
    unittest.main()
