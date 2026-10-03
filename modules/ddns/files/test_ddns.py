import tempfile
import unittest
from pathlib import Path
from unittest import mock

import ddns


def answers(*results):
    def source(index, result):
        def fetch():
            if isinstance(result, Exception):
                raise result
            return result
        return f'source{index}', fetch
    return [source(i, r) for i, r in enumerate(results)]


class FakeRdata:
    def __init__(self, text):
        self.text = text

    def to_text(self):
        return self.text


@mock.patch('ddns.random.sample', lambda sources, k: list(sources))
@mock.patch('ddns.log', lambda message: None)
class FindExternalIp(unittest.TestCase):

    def test_a_failing_first_source_does_not_stop_the_rest(self):
        sources = answers(OSError('Name or service not known'), '80.235.206.44\n',
                          '80.235.206.44')
        self.assertEqual('80.235.206.44', ddns.find_external_ip(sources))

    def test_one_source_cannot_agree_with_itself(self):
        sources = answers('80.235.206.44', OSError('down'), OSError('down'))
        with self.assertRaises(ddns.Error):
            ddns.find_external_ip(sources)

    def test_disagreement_carries_on_until_two_agree(self):
        sources = answers('80.235.206.44', '82.8.16.198', '82.8.16.198', '80.235.206.44')
        self.assertEqual('82.8.16.198', ddns.find_external_ip(sources))

    def test_unusable_answers_are_not_counted(self):
        for bad in ('192.168.50.7', '100.64.0.1', '127.0.0.1', '127.1', '1',
                    '<html>rate limited</html>', '2001:db8::1', ''):
            with self.subTest(bad=bad), self.assertRaises(ddns.Error):
                ddns.find_external_ip(answers(bad, bad, bad))


class AddressFromAnswer(unittest.TestCase):

    def test_a_quoted_txt_address_is_unquoted(self):
        self.assertEqual('80.235.206.44',
                         ddns.address_from_answer([FakeRdata('"80.235.206.44"')]))

    def test_records_that_are_not_addresses_are_skipped(self):
        answer = [FakeRdata('"edns0-client-subnet 80.235.206.0/24"'),
                  FakeRdata('"80.235.206.44"')]
        self.assertEqual('80.235.206.44', ddns.address_from_answer(answer))

    def test_an_answer_with_no_address_fails(self):
        with self.assertRaises(ddns.Error):
            ddns.address_from_answer([FakeRdata('"nothing here"')])


@mock.patch('ddns.log', lambda message: None)
class RecordOutcome(unittest.TestCase):

    def setUp(self):
        scratch = tempfile.TemporaryDirectory()
        self.addCleanup(scratch.cleanup)
        self.state = Path(scratch.name)
        self.sent = []

    def run_at(self, minutes, ok, notify=None):
        ddns.record_outcome(self.state, ok, minutes * 60, notify or self.sent.append)

    def test_no_alert_before_thirty_minutes(self):
        for minutes in range(0, 30, 5):
            self.run_at(minutes, ok=False)
        self.assertEqual([], self.sent)

    def test_one_alert_once_past_thirty_minutes(self):
        for minutes in range(0, 60, 5):
            self.run_at(minutes, ok=False)
        self.assertEqual(1, len(self.sent))
        self.assertIn('30 minutes', self.sent[0])

    def test_a_failed_alert_is_retried(self):
        def broken(message):
            raise OSError('no route to host')
        self.run_at(0, ok=False)
        self.run_at(30, ok=False, notify=broken)
        self.run_at(35, ok=False)
        self.assertEqual(1, len(self.sent))
        self.assertIn('35 minutes', self.sent[0])

    def test_recovery_is_announced_once_and_resets_the_clock(self):
        self.run_at(0, ok=False)
        self.run_at(30, ok=False)
        self.run_at(35, ok=True)
        self.run_at(40, ok=True)
        self.assertEqual(2, len(self.sent))
        self.assertIn('recovered', self.sent[1])
        self.run_at(45, ok=False)
        self.run_at(70, ok=False)
        self.assertEqual(2, len(self.sent))

    def test_recovery_without_an_alert_is_silent(self):
        self.run_at(0, ok=False)
        self.run_at(5, ok=True)
        self.assertEqual([], self.sent)
        self.assertEqual([], list(self.state.iterdir()))


if __name__ == '__main__':
    unittest.main()
