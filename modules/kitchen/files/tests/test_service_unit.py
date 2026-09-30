import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[4]
UNIT = REPO / 'modules/kitchen/files/board/kitchen-board.service'
MANIFEST = REPO / 'modules/kitchen/manifests/board.pp'
KIOSK_UNIT = REPO / 'modules/kitchen/files/kiosk/kitchen-kiosk.service'


class ServiceUnit(unittest.TestCase):

    def test_the_working_directory_is_the_package_parent(self):
        """
        python -m kitchen.app resolves the package from sys.path, which for a
        service is the working directory. Pointing that at the package itself
        instead of its parent gives ModuleNotFoundError on every start, and
        Restart=always turns it into a crash loop rather than an obvious failure.
        """
        unit = UNIT.read_text()
        self.assertIn('WorkingDirectory=/opt\n', unit)
        self.assertIn('-m kitchen.app', unit)
        self.assertIn("file { '/opt/kitchen':", MANIFEST.read_text())


class KioskUnit(unittest.TestCase):

    def test_firefox_waits_for_the_board_to_answer_first(self):
        """
        kitchen-kiosk.service is a user unit and kitchen-board.service is a system
        unit, so there is no After= that can order one against the other. --kiosk
        shows the connection-refused error page and sits on it forever rather than
        exiting, so Restart=always never recovers a race lost against the board.
        """
        unit = KIOSK_UNIT.read_text()
        pre_lines = [line for line in unit.splitlines()
                     if line.startswith('ExecStartPre=')]
        self.assertTrue(pre_lines, 'expected an ExecStartPre= line')
        self.assertIn('127.0.0.1:5273', pre_lines[0])
        # ExecStartPre runs before ExecStart, so it must appear first in the file.
        self.assertLess(unit.index('ExecStartPre='), unit.index('ExecStart='))
