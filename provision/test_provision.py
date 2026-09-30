import base64
import subprocess
import tempfile
import unittest
from pathlib import Path

import yaml

import issue_cert
import provision

EXAMPLE = provision.REPO / 'provision/fleet.example.yaml'
MANIFEST = provision.load_yaml(EXAMPLE)


class Secrets(unittest.TestCase):

    def test_every_reference_in_the_repo_has_a_value(self):
        self.assertEqual([], provision.missing_secrets(MANIFEST))

    def test_a_host_only_gets_its_own_secrets(self):
        kitchen = provision.render_secure(MANIFEST, 'ktcdh1')
        self.assertIn('kitchen_calendar_ids', kitchen)
        self.assertNotIn('backuptool_passphrase', kitchen)

    def test_every_headless_host_has_a_usable_password_hash(self):
        # woolie::managedpassword feeds this straight to the user resource, so a
        # malformed value leaves the account locked and sshd refuses it: exactly the
        # lockout the class exists to prevent. Fail here instead, on the desktop.
        for hostname in ('ktcdh1', 'blrsh1', 'websh1'):
            value = MANIFEST['hosts'][hostname].get('woolie_password_hash')
            self.assertIsNotNone(value, f'{hostname} has no woolie_password_hash')
            self.assertRegex(value, r'^\$(y|7|6|gy)\$[^$]+\$.+',
                             f'{hostname} hash is not a crypt(3) string')

    def test_a_workstation_stores_no_password_hash(self):
        # Workstations are set up at a keyboard, so they have no lockout to solve.
        # Keeping the hash off them means nothing about the password typed into an
        # encrypted machine is written down anywhere.
        for hostname in ('lendh1', 'ltpdh1', 'hplaptop2'):
            self.assertNotIn('woolie_password_hash',
                             provision.render_secure(MANIFEST, hostname))

    def test_puppet_reads_back_what_went_in(self):
        with tempfile.TemporaryDirectory() as scratch:
            root = Path(scratch)
            manifests = root / 'modules/secure/manifests'
            manifests.mkdir(parents=True)
            (manifests / 'init.pp').write_text(provision.render_secure(MANIFEST, 'websh1'))
            out = root / 'out'
            subprocess.run(
                ['puppet', 'apply', '--modulepath', str(root / 'modules'),
                 '--strict_variables', '-e',
                 f'include secure\nfile {{ "{out}": content => $secure::backuptool_passphrase }}'],
                check=True, capture_output=True)
            expected = MANIFEST['hosts']['websh1']['backuptool_passphrase']
            self.assertRegex(expected, r"[$'\\]")
            self.assertEqual(expected, out.read_text())

    def test_the_seed_has_everything_needed_to_reach_the_box(self):
        # A wrong seed means a headless Pi that never appears, so check the four
        # things that would strand it: sshd, the key, the address and the wifi.
        with tempfile.TemporaryDirectory() as scratch:
            boot = Path(scratch)
            (boot / 'config.txt').touch()
            provision.seed(MANIFEST, 'ktcdh1', boot)

            user_data = yaml.safe_load((boot / 'user-data').read_text())
            network = yaml.safe_load((boot / 'network-config').read_text())

        # sshd has to be installed and the apt lock waited for, or the box comes
        # up with nothing listening. The account has to end up with a '*' rather
        # than a '!', or sshd refuses it however good the key is.
        self.assertTrue(any('install -y openssh-server' in c for c in user_data['runcmd']))
        self.assertTrue(all('DPkg::Lock::Timeout' in c
                            for c in user_data['runcmd'] if 'apt-get' in c))
        self.assertIn('dpkg --configure -a', user_data['runcmd'])
        self.assertIn("usermod -p '*' tmpbootstrap", user_data['runcmd'])
        # ssh_pwauth would have cloud-init write an sshd_config before sshd exists,
        # which dpkg then keeps, leaving the box without an sftp subsystem.
        self.assertNotIn('ssh_pwauth', user_data)

        user = user_data['users'][0]
        self.assertEqual('tmpbootstrap', user['name'])
        self.assertNotIn('default', user_data['users'])
        self.assertTrue(user['ssh_authorized_keys'][0].startswith('ssh-ed25519 '))
        self.assertNotIn('ssh_import_id', str(user_data))

        wlan = network['wifis']['wlan0']
        self.assertEqual(['192.168.50.9/24'], wlan['addresses'])
        self.assertEqual('192.168.50.1', wlan['routes'][0]['via'])
        self.assertEqual('GB', wlan['regulatory-domain'])
        self.assertFalse(wlan['optional'])
        self.assertIn('ExampleNetwork', wlan['access-points'])

    def test_the_seed_refuses_a_host_with_no_address(self):
        with tempfile.TemporaryDirectory() as scratch:
            boot = Path(scratch)
            (boot / 'config.txt').touch()
            with self.assertRaises(provision.Error):
                provision.seed(MANIFEST, 'pxlmh1', boot)

    def render_netplan(self, hostname):
        """Render raspi::network's template the way the manifest calls it."""
        fleet = MANIFEST['fleet']
        addresses = MANIFEST['hosts'][hostname]['addresses']
        wifis = {i: a for i, a in addresses.items() if provision.is_wifi(i)}
        ethernets = {i: a for i, a in addresses.items() if not provision.is_wifi(i)}
        as_hash = (lambda d: '{' + ', '.join(f"'{k}' => '{v}'" for k, v in d.items()) + '}')
        values = ', '.join([
            f'ethernets => {as_hash(ethernets)}',
            f'wifis => {as_hash(wifis)}',
            f"gateway => '{fleet['gateway']}'",
            'nameservers => [' + ', '.join(f"'{n}'" for n in fleet['nameservers']) + ']',
            f"regulatory_domain => '{fleet['regulatory_domain']}'",
            f"wifi_ssid => '{fleet['wifi_ssid']}'",
            f"wifi_password => '{fleet['wifi_password']}'",
        ])
        rendered = subprocess.run(
            ['puppet', 'epp', 'render',
             str(provision.REPO / 'modules/raspi/templates/49-netplan-woolie.yaml.epp'),
             '--values', '{' + values + '}'],
            capture_output=True, text=True, check=True).stdout
        return yaml.safe_load(rendered)['network']

    def seeded_network(self, hostname):
        with tempfile.TemporaryDirectory() as scratch:
            boot = Path(scratch)
            (boot / 'config.txt').touch()
            provision.seed(MANIFEST, hostname, boot)
            return yaml.safe_load((boot / 'network-config').read_text())

    def test_the_netplan_puppet_writes_agrees_with_the_seed(self):
        # raspi::network deletes the seed's netplan and replaces it, so if this file
        # disagreed the host would move address on the first reboot, with no console
        # to find it from. Checked for wifi only and for a host with both.
        for hostname in ('ktcdh1', 'blrsh1'):
            seeded = self.seeded_network(hostname)
            applied = self.render_netplan(hostname)
            for section in ('ethernets', 'wifis'):
                self.assertEqual(sorted(seeded.get(section, {})),
                                 sorted(applied.get(section, {})),
                                 f'{hostname} {section} interfaces differ')
                for interface, config in seeded.get(section, {}).items():
                    live = applied[section][interface]
                    self.assertFalse(live['dhcp4'])
                    self.assertEqual(config['addresses'], live['addresses'])
                    self.assertEqual(config['routes'][0]['via'], live['routes'][0]['via'])
                    self.assertEqual(config['routes'][0]['metric'],
                                     live['routes'][0]['metric'],
                                     f'{interface} route metric differs')

    def test_ethernet_outranks_wifi_when_a_host_has_both(self):
        # Two default routes of equal cost would make the active one a toss-up.
        network = self.seeded_network('blrsh1')
        self.assertLess(network['ethernets']['eth0']['routes'][0]['metric'],
                        network['wifis']['wlan0']['routes'][0]['metric'])

    def test_only_the_expected_interface_holds_up_the_boot(self):
        # An unplugged cable must not delay a Pi that is on wifi, and vice versa.
        both = self.seeded_network('blrsh1')
        self.assertFalse(both['wifis']['wlan0']['optional'])
        self.assertTrue(both['ethernets']['eth0']['optional'])

        wired = self.seeded_network('websh1')
        self.assertFalse(wired['ethernets']['eth0']['optional'])
        self.assertNotIn('wifis', wired)

    def test_an_unfilled_placeholder_is_refused(self):
        # A present-but-placeholder value would otherwise sail through and break
        # something at runtime instead of here.
        manifest = {'fleet': {'wifi_ssid': 'REPLACE_ME'},
                    'hosts': {'ktcdh1': {'role': 'pi'}}}
        with self.assertRaises(provision.Error) as caught:
            provision.render_secure(manifest, 'ktcdh1')
        self.assertIn('wifi_ssid', str(caught.exception))

    def test_the_install_script_does_not_hand_install_a_numeric_group(self):
        # install refuses a group that does not exist yet, which every PKI file
        # hits on a fresh box, so ownership has to be a separate chown.
        script = provision.install_script(
            '/tmp/staging',
            [{'path': '/etc/wooldrigepki/certificates/client.pem',
              'mode': '0640', 'group': provision.PKI_GROUP}])
        install = [l for l in script.splitlines() if l.startswith('install ')]
        self.assertTrue(install)
        for line in install:
            self.assertNotRegex(line, r' -[og] ')
        self.assertIn(f"chown 0:{provision.PKI_GROUP} "
                      "'/etc/wooldrigepki/certificates/client.pem'", script)
        with tempfile.TemporaryDirectory() as scratch:
            path = Path(scratch) / 'install.sh'
            path.write_text(script)
            subprocess.run(['sh', '-n', str(path)], check=True)

    def test_backuptool_reads_its_own_credentials_section(self):
        # The real extraction, lifted from modules/backuptool/files/backuptool. It
        # must find the [backuptool] profile and not the [ddns] one above it.
        rendered = provision.aws_credentials(MANIFEST['artefacts']['aws_profiles'])
        self.assertIn('[ddns]', rendered)
        self.assertIn('[backuptool]', rendered)
        with tempfile.TemporaryDirectory() as scratch:
            path = Path(scratch) / 'credentials'
            path.write_text(rendered)
            found = subprocess.run(
                ['sh', '-c',
                 f"sed -n '/^\\[backuptool\\]/,/^\\[/p' {path}"
                 " | sed -n 's/^aws_access_key_id[[:space:]]*=[[:space:]]*//p' | head -n1"],
                capture_output=True, text=True)
        expected = MANIFEST['artefacts']['aws_profiles']['backuptool']['access_key_id']
        self.assertEqual(expected, found.stdout.strip())
        self.assertNotEqual(MANIFEST['artefacts']['aws_profiles']['ddns']['access_key_id'],
                            found.stdout.strip())


class Certificates(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.scratch = tempfile.TemporaryDirectory()
        root = Path(cls.scratch.name)
        cls.ca_key = root / 'ca.key'
        cls.ca_cert = root / 'ca.pem'
        subprocess.run(['openssl', 'genpkey', '-algorithm', 'ed25519',
                        '-out', str(cls.ca_key)], check=True, capture_output=True)
        subprocess.run(['openssl', 'req', '-x509', '-new', '-key', str(cls.ca_key),
                        '-days', '30', '-subj', '/O=WooldrigePKI/CN=test root',
                        '-out', str(cls.ca_cert)], check=True, capture_output=True)

    @classmethod
    def tearDownClass(cls):
        cls.scratch.cleanup()

    def test_a_leaf_verifies_and_its_dn_matches_the_nginx_map(self):
        for hostname, expected in (('ktcdh1', 'desktop'), ('blrsh1', 'server'),
                                   ('hplaptop2', 'desktop')):
            certificate, _ = issue_cert.issue(hostname, self.ca_key, self.ca_cert)
            issue_cert.verify(certificate, self.ca_cert)
            self.assertEqual(f'CN={hostname},OU={expected},O=WooldrigePKI',
                             certificate.subject.rfc4514_string())

    def test_a_phone_gets_rsa_and_a_bundle_openssl_can_read(self):
        certificate, document = issue_cert.issue('pxlmh1', self.ca_key, self.ca_cert)
        self.assertEqual('CN=pxlmh1,OU=mobile,O=WooldrigePKI',
                         certificate.subject.rfc4514_string())
        with tempfile.TemporaryDirectory() as scratch:
            path = Path(scratch) / 'bundle.p12'
            path.write_bytes(base64.b64decode(document['pkcs12_base64']))
            result = subprocess.run(
                ['openssl', 'pkcs12', '-in', str(path), '-info', '-nodes',
                 '-passin', f'pass:{document["pkcs12_password"]}'],
                capture_output=True, text=True)
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertIn('CN=pxlmh1', result.stdout)


if __name__ == '__main__':
    unittest.main()
