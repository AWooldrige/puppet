import re
import unittest
from pathlib import Path

from kitchen import scheduler

STATIC = Path(__file__).resolve().parent.parent / 'kitchen/static'
HTML = (STATIC / 'index.html').read_text()
CSS = (STATIC / 'board.css').read_text()
JS = (STATIC / 'board.js').read_text()


def z_index(name):
    block = re.search(r'^\.' + re.escape(name) + r'\s*\{([^}]*)\}', CSS, re.M)
    return int(re.search(r'z-index:\s*(\d+)', block.group(1)).group(1))


class Shell(unittest.TestCase):

    def test_the_day_popup_is_drawn_over_the_board_and_frames(self):
        self.assertGreater(z_index('overlay'), z_index('frame-error'))
        self.assertGreater(z_index('overlay'), z_index('board'))
        self.assertLess(z_index('overlay'), z_index('wake-shield'))

    def test_every_colour_has_a_dark_value(self):
        def colours(selector):
            block = re.search(re.escape(selector) + r'\s*\{([^}]*)\}', CSS).group(1)
            return {name for name, value in re.findall(r'(--[\w-]+):\s*([^;]+);', block)
                    if re.match(r'#|rgba?\(', value.strip())}
        light = colours(':root')
        self.assertIn('--paper', light)
        self.assertEqual(light, colours('html[data-theme="dark"]'))

    def test_the_lock_covers_everything_but_still_lets_the_wake_touch_be_absorbed(self):
        self.assertGreater(z_index('lock'), z_index('overlay'))
        self.assertLess(z_index('lock'), z_index('wake-shield'))

    def test_anything_hidden_can_actually_be_hidden(self):
        """
        A class that sets display beats the hidden attribute, because the user
        agent's [hidden] rule is weaker. The board sits behind an absolutely
        positioned error panel, so getting this wrong paints the error over every
        tab and looks like a network fault rather than a stylesheet one.
        """
        classes = set()
        for tag in re.findall(r'<[^>]*\bhidden\b[^>]*>', HTML):
            found = re.search(r'class="([^"]+)"', tag)
            if found:
                classes.update(found.group(1).split())
        self.assertIn('frame-error', classes, 'expected the error panel to be hidden')

        for name in sorted(classes):
            block = re.search(r'\.' + re.escape(name) + r'\s*\{([^}]*)\}', CSS)
            if block and re.search(r'\bdisplay\s*:', block.group(1)):
                self.assertRegex(
                    CSS, r'\.' + re.escape(name) + r'\[hidden\]',
                    f'.{name} sets display, so it needs a [hidden] override')

    def test_the_tab_names_are_the_ones_the_controller_matches(self):
        # Labels are free to change; these values go to /api/page and drive the
        # revert-to-board rule.
        tabs = re.findall(r'data-tab="([^"]+)"', HTML)
        self.assertIn(scheduler.BOARD_PAGE, tabs)
        self.assertEqual(
            ['board', 'money', 'home', 'graphs', 'status', 'lock', 'screenoff'], tabs)

    def test_home_and_graphs_each_get_their_own_persistent_frame(self):
        """
        One shared iframe reset to about:blank on every tab switch was what made
        Control and Graphs slow to open: the whole page had to reload from
        scratch every time. Two frames, each left pointed at its URL once loaded,
        is what makes a repeat visit instant.
        """
        self.assertIn('id="frame-home"', HTML)
        self.assertIn('id="frame-graphs"', HTML)
        self.assertNotIn('id="frame"', HTML)
        self.assertIn("frames: { home: el('frame-home'), graphs: el('frame-graphs') }",
                       JS)
        # Never reset a frame back to about:blank once loaded: that was what forced
        # a full reload on every visit. (It's fine for the word to appear in a
        # comment explaining that; only an actual assignment matters here.)
        self.assertNotRegex(JS, r"\.src\s*=\s*['\"]about:blank")

    def test_calendar_only_chrome_is_toggled_by_tab(self):
        """
        The date and weather rows describe the calendar; Control and Graphs fill
        that space with their own UI. Only the tab bar should stay up on every
        screen.
        """
        self.assertIn("show(dom.topbar, onBoard)", JS)
        self.assertIn("show(dom.weather, onBoard)", JS)
        self.assertNotIn('id="status"', HTML)

    def test_frames_render_in_the_background_rather_than_being_hidden(self):
        for frame in re.findall(r'<iframe[^>]*>', HTML):
            self.assertNotIn(' hidden', frame)
        self.assertNotRegex(JS, r'show\((frame|otherFrame|dom\.frames\[name\]),')
        self.assertRegex(CSS, r'\.board \{[^}]*z-index: 1;[^}]*background: var\(--paper\)')

    def test_every_el_lookup_has_a_matching_id_in_the_html(self):
        """
        el(id) returns null for a ref removed from the HTML but left in the dom
        object. wire() calling .addEventListener on that null throws synchronously,
        which aborts start() before the first board poll and leaves the shell
        showing nothing but placeholders with no error visible anywhere.
        """
        html_ids = set(re.findall(r'\bid="([^"]+)"', HTML))
        js_ids = set(re.findall(r"\bel\('([^']+)'\)", JS))
        missing = js_ids - html_ids
        self.assertFalse(
            missing,
            f'board.js looks up id(s) not present in index.html: {sorted(missing)}')
