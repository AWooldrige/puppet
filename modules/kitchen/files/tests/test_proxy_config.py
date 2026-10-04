import re
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[4]
PROXY = REPO / 'modules/kitchen/files/proxy/kitchen-proxy.nginx'


class ProxyConfig(unittest.TestCase):

    def setUp(self):
        """
        Comments are stripped because this file explains these directives at
        length, and counting them would match the prose rather than the config.
        """
        kept = (line.split('#', 1)[0] for line in PROXY.read_text().splitlines())
        self.config = '\n'.join(line for line in kept if line.strip())

    def test_session_reuse_is_off_wherever_a_server_name_is_set(self):
        """
        The two listeners share one upstream address and differ only by
        proxy_ssl_name. nginx caches the upstream session against the address, so
        reuse hands one vhost a session belonging to the other and the upstream
        rejects it. Whichever tab is opened second gets a 502.
        """
        names = self.config.count('proxy_ssl_name ')
        self.assertGreater(names, 1, 'expected both listeners to set proxy_ssl_name')
        self.assertEqual(names, self.config.count('proxy_ssl_session_reuse off;'))

    def test_the_server_name_is_actually_put_on_the_wire(self):
        # proxy_ssl_name does nothing without proxy_ssl_server_name on, and the
        # upstream then serves its default vhost instead.
        self.assertEqual(self.config.count('proxy_ssl_name '),
                         self.config.count('proxy_ssl_server_name on;'))

    def test_the_grafana_listener_proxies_nothing_but_grafana(self):
        # The device must not reach anything else on that vhost, whatever the
        # server side allows.
        grafana = self.config[self.config.index('listen 127.0.0.1:5275;'):]
        locations = re.findall(r'location\s+([^{]+?)\s*\{', grafana)
        self.assertEqual(sorted(locations), [
            '/', '/grafana/', '= /grafana', '= /kitchen/envelopes.json'])
        self.assertIn('return 403', grafana)

    def test_both_listeners_are_loopback_only(self):
        for port in ('5274', '5275'):
            self.assertIn(f'listen 127.0.0.1:{port};', self.config)
        self.assertIn('deny all;', self.config)
        self.assertFalse(re.search(r'^\s*listen\s+(?!127\.0\.0\.1)', self.config, re.M))
