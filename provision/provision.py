#!/usr/bin/env python3
"""Push a host its secrets, certificates and credentials."""

import argparse
import re
import subprocess
import sys
import time
from pathlib import Path

import yaml

REPO = Path(__file__).resolve().parent.parent
SECURE_REFERENCE = re.compile(r'\$secure::([a-z_][a-z0-9_]*)')

# Numeric ids so files can land before Puppet has created the groups. The PKI
# group's id is pinned in the manifests.
ROOT = '0'
PKI_GROUP = '19004'

MANAGED = ('desktop', 'pi', 'server')

# role picks which files a host gets, so it is provisioning bookkeeping rather
# than something the manifests read.
NOT_SECRETS = ('role',)

# The temporary user cloud-init creates, deleted once woolie works.
BOOTSTRAP_USER = 'tmpbootstrap'

FILES = (
    {'path': '/etc/wooldrigepki/certificates/client.pem', 'mode': '0640',
     'group': PKI_GROUP, 'source': 'cert:certificate', 'roles': MANAGED},
    {'path': '/etc/wooldrigepki/privatekeys/client.pem', 'mode': '0640',
     'group': PKI_GROUP, 'source': 'cert:private_key', 'roles': MANAGED},
    {'path': '/etc/wooldrigepki/certificates/server.pem', 'mode': '0640',
     'group': PKI_GROUP, 'source': 'server:certificate', 'roles': ('server',)},
    {'path': '/etc/wooldrigepki/privatekeys/server.pem', 'mode': '0640',
     'group': PKI_GROUP, 'source': 'server:private_key', 'roles': ('server',)},
    {'path': '/etc/securepuppet/modules/secure/manifests/init.pp', 'mode': '0600',
     'source': 'secure', 'roles': MANAGED},
    {'path': '/etc/aws/ddns.credentials', 'mode': '0600',
     'source': 'aws:ddns', 'roles': ('server',)},
    {'path': '/etc/aws/backuptool.credentials', 'mode': '0600',
     'source': 'aws:backuptool', 'roles': ('server',)},
)


class Error(Exception):
    pass


def load_yaml(path):
    text = Path(path).read_text()
    if re.search(r'^sops:$', text, re.MULTILINE):
        text = run(['sops', '--decrypt', '--output-type', 'yaml', str(path)])
    return yaml.safe_load(text)


def run(argv, content=None):
    result = subprocess.run(argv, input=content, capture_output=True, text=True)
    if result.returncode != 0:
        raise Error(f'{argv[0]} failed: {result.stderr.strip().splitlines()[-1]}')
    return result.stdout


def quote(value):
    return "'" + value.replace('\\', '\\\\').replace("'", "\\'") + "'"


def heredoc(value):
    tag = 'EOT'
    while tag in (line.strip() for line in value.split('\n')):
        tag += 'X'
    lines = value.split('\n')
    chomp = '' if lines[-1] == '' else '-'
    body = lines[:-1] if lines[-1] == '' else lines
    return '\n'.join([f'@({tag})'] + [f'        {line}' if line else '' for line in body]
                     + [f'        | {chomp}{tag}'])


def render_value(value):
    if isinstance(value, bool):
        raise Error(f'{value!r} is a boolean, which no secret should be')
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, list):
        return '[' + ', '.join(quote(item) for item in value) + ']'
    if isinstance(value, dict):
        return '{' + ', '.join(f'{quote(k)} => {render_value(v)}'
                               for k, v in value.items()) + '}'
    if '\n' in value:
        return heredoc(value)
    return quote(value)


def host_section(manifest, hostname):
    host = manifest['hosts'].get(hostname)
    if host is None:
        raise Error(f'{hostname} is not in the manifest: {", ".join(manifest["hosts"])}')
    return host


def secrets_for(manifest, hostname):
    host = host_section(manifest, hostname)
    values = {**manifest['fleet'],
              **{k: v for k, v in host.items() if k not in NOT_SECRETS}}
    if unset := sorted(k for k, v in values.items() if 'REPLACE_ME' in str(v)):
        raise Error(f'{hostname}: still a placeholder for {", ".join(unset)}')
    return values


def woolie_public_key():
    """Read the key out of the manifest that is authoritative for it."""
    prefs = (REPO / 'modules/woolie/manifests/ubuntuprefs.pp').read_text()
    kind = re.search(r"type\s*=>\s*'(ssh-[^']+)'", prefs)
    key = re.search(r"key\s*=>\s*'([A-Za-z0-9+/=]+)'", prefs)
    if not (kind and key):
        raise Error('could not find the ssh_authorized_key in ubuntuprefs.pp')
    return f'{kind.group(1)} {key.group(1)} woolie'


def is_wifi(interface):
    return interface.startswith(('wl', 'wifi'))


def primary_interface(addresses):
    wifis = sorted(i for i in addresses if is_wifi(i))
    return wifis[0] if wifis else sorted(addresses)[0]


def route_metric(interface):
    return 600 if is_wifi(interface) else 100


def seed(manifest, hostname, mountpoint):
    """
    Write the cloud-init seed to a freshly flashed boot partition.

    Everything is local: the SSH key is embedded rather than pulled with
    ssh_import_id
    """
    network = manifest['fleet']
    addresses = host_section(manifest, hostname).get('addresses')
    if not addresses:
        raise Error(f'{hostname} has no addresses in the manifest, needed for the seed')

    mountpoint = Path(mountpoint)
    if not (mountpoint / 'config.txt').exists():
        raise Error(
            f'{mountpoint} has no config.txt, so it is not a Pi boot partition. '
            'The usual cause is writing the wrong image: it must be '
            'ubuntu-<ver>-preinstalled-desktop-arm64+raspi.img.xz, not the '
            'ubuntu-<ver>-desktop-arm64.iso installer, which has no seed location.')

    user_data = {
        'hostname': hostname,
        # Deliberately no ssh_pwauth. Setting it makes cloud-init write a one line
        # sshd_config before sshd is installed, and dpkg then keeps that file as a
        # conffile, so the box runs with no Subsystem sftp (scp fails with
        # "Connection closed") and UsePAM defaulted off. It protects nothing
        # either: no account has a usable password until the apply has already put
        # PasswordAuthentication no in place.
        #
        # The desktop image ships openssh-client but no server, so a desktop Pi
        # is unreachable until this runs. Already present on the server image.
        #
        # Not the packages: key, which cannot wait for the apt lock that
        # unattended-upgrades holds early in the first boot, and cannot repair a
        # dpkg left interrupted by a power cut. Either makes apt exit 100.
        #
        # The usermod turns the '!' that lock_passwd leaves in the shadow file
        # into a '*'. Both refuse every password, but sshd rejects a '!' account
        # outright with "account is locked", before it looks at the key.
        #
        # The server image already has sshd, so the guard skips the apt work
        # entirely there rather than waiting on a lock to do nothing.
        'runcmd': [
            f"usermod -p '*' {BOOTSTRAP_USER}",
            'dpkg --configure -a',
            '[ -x /usr/sbin/sshd ] || { apt-get -o DPkg::Lock::Timeout=1800 update'
            ' && apt-get -o DPkg::Lock::Timeout=1800 install -y openssh-server; }',
        ],
        # No 'default' entry, so no ubuntu user with a known password is created.
        'users': [{
            'name': BOOTSTRAP_USER,
            'lock_passwd': True,
            'shell': '/bin/bash',
            'groups': ['adm', 'sudo'],
            'sudo': ['ALL=(ALL) NOPASSWD:ALL'],
            'ssh_authorized_keys': [woolie_public_key()],
        }],
    }
    network_config = {'version': 2}
    for interface, address in sorted(addresses.items()):
        section = 'wifis' if is_wifi(interface) else 'ethernets'
        config = {
            # optional: false on the one interface we expect to reach the box by
            # makes cloud-init wait for it rather than carrying on with no network.
            # The others must stay optional, or an unplugged cable holds up the boot.
            'optional': interface != primary_interface(addresses),
            'dhcp4': False,
            'addresses': [f'{address}/24'],
            'routes': [{'to': 'default', 'via': network['gateway'],
                        'metric': route_metric(interface)}],
            'nameservers': {'addresses': network['nameservers']},
        }
        if is_wifi(interface):
            config['regulatory-domain'] = network['regulatory_domain']
            config['access-points'] = {
                network['wifi_ssid']: {'password': network['wifi_password']},
            }
        network_config.setdefault(section, {})[interface] = config

    # width stops safe_dump folding the SSH key across lines. YAML rejoins it
    # correctly, but a wrapped key reads like corruption.
    def dump(document):
        return yaml.safe_dump(document, default_flow_style=False, width=4096)

    # cloud-init only re-runs when the instance-id changes, so a fresh one each
    # time makes re-seeding an already-booted card take effect on next boot.
    instance = f'{hostname}-{int(time.time())}'

    (mountpoint / 'meta-data').write_text(f'instance-id: {instance}\n')
    (mountpoint / 'user-data').write_text('#cloud-config\n' + dump(user_data))
    (mountpoint / 'network-config').write_text(dump(network_config))

    print(f'{hostname} seeded on {mountpoint}')
    for interface, address in sorted(addresses.items()):
        print(f'  {interface:<8} {address}  metric {route_metric(interface)}')
    print(f'  gateway  {network["gateway"]}')
    print(f'  ssh      {BOOTSTRAP_USER}@{addresses[primary_interface(addresses)]}')


def render_secure(manifest, hostname):
    body = '\n'.join(f'    ${name} = {render_value(value)}'
                     for name, value in sorted(secrets_for(manifest, hostname).items()))
    return f'# Written by provision.py for {hostname}\nclass secure {{\n{body}\n}}\n'


def aws_credentials(name, values):
    return (f'[{name}]\n'
            f'aws_access_key_id={values["access_key_id"]}\n'
            f'aws_secret_access_key={values["secret_access_key"]}\n')


def missing_secrets(manifest):
    """$secure:: names the manifests read that the manifest has no value for."""
    available = set(manifest['fleet'])
    for host in manifest['hosts'].values():
        available |= set(host)
    referenced = set()
    for directory in ('manifests', 'modules'):
        for path in (REPO / directory).rglob('*'):
            if path.suffix in ('.pp', '.epp'):
                referenced |= set(SECURE_REFERENCE.findall(path.read_text()))
    return sorted(referenced - available)


def content_for(source, hostname, manifest, certs):
    kind, _, field = source.partition(':')
    if kind == 'secure':
        return render_secure(manifest, hostname)
    if kind == 'aws':
        return aws_credentials(field, manifest['artefacts']['aws_profiles'][field])
    suffix = '-server' if kind == 'server' else ''
    path = Path(certs) / f'{hostname}{suffix}.yaml'
    if not path.exists():
        raise Error(f'{path} is missing, issue it with issue_cert.py')
    return load_yaml(path)[field]


def plan(manifest, hostname, certs):
    role = manifest['hosts'][hostname]['role'] if hostname in manifest['hosts'] else None
    if role == 'mobile':
        raise Error(f'{hostname} is a phone: issue its certificate and import it by hand')
    if missing := missing_secrets(manifest):
        raise Error(f'no value in the manifest for: {", ".join(missing)}')
    files = [dict(spec, content=content_for(spec['source'], hostname, manifest, certs))
             for spec in FILES if role in spec['roles']]
    if placeholders := [f['path'] for f in files if 'REPLACE_ME' in f['content']]:
        raise Error(f'still a placeholder in: {", ".join(placeholders)}')
    return files


def install_script(staging, files):
    """
    The ownership is a separate chown because install rejects a numeric group
    that does not exist yet, and these files exist before Puppet has created the
    users and groups.
    """
    lines = ['set -eu']
    for index, spec in enumerate(files):
        lines.append(f"install -D -m {spec['mode']} {staging}/{index} '{spec['path']}'")
        lines.append(f"chown {spec.get('owner', ROOT)}:{spec.get('group', ROOT)} "
                     f"'{spec['path']}'")
    return '\n'.join(lines) + '\n'


def push(destination, files, port=None):
    # A host that has been applied has sshd on 3222, so re-provisioning one needs
    # either the port or an ssh_config entry for it.
    ssh = ['ssh'] + (['-p', str(port)] if port else [])
    staging = run(ssh + [destination, 'mktemp -d']).strip()
    try:
        for index, spec in enumerate(files):
            run(ssh + [destination, f'umask 077 && cat > {staging}/{index}'],
                content=spec['content'])
            print(f"  {spec['path']}")
        run(ssh + [destination, f'cat > {staging}/install.sh'],
            content=install_script(staging, files))
        subprocess.run(ssh + ['-tt', destination, f'sudo sh {staging}/install.sh'],
                       check=True)
    finally:
        subprocess.run(ssh + [destination, f'rm -rf {staging}'])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('hostname', nargs='?')
    parser.add_argument('--all', action='store_true')
    parser.add_argument('--fleet', required=True)
    parser.add_argument('--certs')
    parser.add_argument('--ssh', help='ssh destination, defaults to the hostname')
    parser.add_argument('--port', help='ssh port, for a host not yet in ssh_config')
    parser.add_argument('--show', action='store_true', help='print the secure class and stop')
    parser.add_argument('--seed', metavar='MOUNTPOINT',
                        help='write a cloud-init seed to a flashed boot partition')
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()

    if bool(args.hostname) == bool(args.all):
        parser.error('give either a hostname or --all')
    if args.all and args.ssh:
        parser.error('--ssh with --all would push every host to one machine')
    if not (args.certs or args.show or args.seed):
        parser.error('--certs is needed to push')

    try:
        manifest = load_yaml(args.fleet)
        if args.show:
            sys.stdout.write(render_secure(manifest, args.hostname))
            return 0
        if args.seed:
            seed(manifest, args.hostname, args.seed)
            return 0

        hosts = ([h for h, s in manifest['hosts'].items() if s['role'] != 'mobile']
                 if args.all else [args.hostname])
        for hostname in hosts:
            files = plan(manifest, hostname, args.certs)
            print(hostname)
            if args.dry_run:
                for spec in files:
                    print(f"  {spec['path']}  {spec['mode']}")
            else:
                push(args.ssh or hostname, files, args.port)
    except Error as error:
        print(f'ERROR: {error}', file=sys.stderr)
        return 2
    return 0


if __name__ == '__main__':
    sys.exit(main())
