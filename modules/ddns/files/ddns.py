#!/usr/bin/env python3
#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
import ipaddress
import os
import random
import socket
import subprocess
import sys
import time
import traceback
from collections import Counter
from pathlib import Path

import boto3
import click
import requests
import urllib3.util.connection

DNS_NAME = 'h.wooldrige.co.uk.'
DNS_TTL = 60
HOSTED_ZONE = 'Z1VIBQX07I3Y3K'
AWS_PROFILE = 'ddns'
MIN_AGREE = 2
TIMEOUT = 5
ALERT_AFTER_MINUTES = 30

urllib3.util.connection.allowed_gai_family = lambda: socket.AF_INET


class Error(Exception):
    pass


def log(message):
    click.echo(message)


def parse_ip(text):
    ip = ipaddress.IPv4Address(text.strip())
    if not ip.is_global:
        raise ValueError(f'{ip} is not a public address')
    return str(ip)


def https_source(url):
    def fetch():
        response = requests.get(url, timeout=TIMEOUT)
        response.raise_for_status()
        return response.text
    return url, fetch


def address_from_answer(answer):
    for rdata in answer:
        text = rdata.to_text().strip('"')
        try:
            return str(ipaddress.IPv4Address(text))
        except ValueError:
            continue
    raise Error('no address in the answer')


def dns_source(qname, rdtype, server):
    def fetch():
        import dns.resolver
        resolver = dns.resolver.Resolver(configure=False)
        resolver.nameservers = [server]
        return address_from_answer(resolver.resolve(qname, rdtype, lifetime=TIMEOUT))
    return f'{qname} {rdtype} @{server}', fetch


SOURCES = [
    https_source('https://checkip.amazonaws.com'),
    https_source('https://api.ipify.org'),
    https_source('https://ipv4.icanhazip.com'),
    https_source('https://ifconfig.co/ip'),
    https_source('https://api-ipv4.ip.sb/ip'),
    https_source('https://ifconfig.me/ip'),
    https_source('https://ipinfo.io/ip'),
    https_source('https://v4.ident.me'),
    https_source('https://ipv4.wtfismyip.com/text'),
    https_source('https://ipecho.net/plain'),
    dns_source('myip.opendns.com.', 'A', '208.67.222.222'),
    dns_source('o-o.myaddr.l.google.com.', 'TXT', '216.239.32.10'),
    dns_source('whoami.akamai.net.', 'A', '193.108.88.1'),
]


def find_external_ip(sources):
    votes = Counter()
    for name, fetch in random.sample(sources, len(sources)):
        try:
            ip = parse_ip(fetch())
        except Exception as e:
            log(f' * {name} failed: {e}')
            continue
        log(f' * {name} says {ip}')
        votes[ip] += 1
        if votes[ip] >= MIN_AGREE:
            return ip
    raise Error(f'no {MIN_AGREE} sources agreed: {dict(votes)}')


def current_route53_ip(r53):
    rrs = r53.list_resource_record_sets(
        HostedZoneId=HOSTED_ZONE, StartRecordName=DNS_NAME, StartRecordType='A',
        MaxItems='1')['ResourceRecordSets']
    record = next((r for r in rrs if r['Name'] == DNS_NAME and r['Type'] == 'A'), None)
    return record['ResourceRecords'][0]['Value'] if record else None


def update_route53(ip, dryrun, forceupdate):
    os.environ.setdefault('AWS_SHARED_CREDENTIALS_FILE', '/etc/aws/ddns.credentials')
    r53 = boto3.Session(profile_name=AWS_PROFILE).client('route53')
    current = current_route53_ip(r53)
    log(f'Route53 has {current}')
    if current == ip and not forceupdate:
        log('Route53 is up to date')
        return
    if dryrun:
        log(f'Dry run, so not changing Route53 to {ip}')
        return
    change = r53.change_resource_record_sets(
        HostedZoneId=HOSTED_ZONE,
        ChangeBatch={
            'Comment': f'Update {DNS_NAME} to {ip}',
            'Changes': [{
                'Action': 'UPSERT',
                'ResourceRecordSet': {
                    'Name': DNS_NAME, 'Type': 'A', 'TTL': DNS_TTL,
                    'ResourceRecords': [{'Value': ip}],
                },
            }],
        })['ChangeInfo']['Id']
    log(f'Route53 change {change} submitted, waiting for it to apply')
    r53.get_waiter('resource_record_sets_changed').wait(
        Id=change, WaiterConfig={'Delay': 10, 'MaxAttempts': 18})
    log(f'Route53 now has {ip}')


def escalate(message):
    subprocess.run(['/usr/local/sbin/escalate', message], check=True, timeout=60)


def notified(notify, message):
    try:
        notify(message)
        return True
    except Exception as e:
        log(f'Could not send the alert, will retry next run: {e}')
        return False


def record_outcome(state_dir, ok, now, notify):
    failing_since = state_dir / 'failing-since'
    alerted = state_dir / 'alerted'
    if ok:
        failing_since.unlink(missing_ok=True)
        if alerted.exists() and notified(notify, f'ddns has recovered, {DNS_NAME} is up to date'):
            alerted.unlink()
        return
    if not failing_since.exists():
        failing_since.write_text(str(now))
    minutes = (now - float(failing_since.read_text())) / 60
    log(f'Updates have been failing for {minutes:.0f} minutes')
    if minutes >= ALERT_AFTER_MINUTES and not alerted.exists() and notified(
            notify, f'ddns has failed for {minutes:.0f} minutes, so {DNS_NAME} may be '
                    'stale. See journalctl -t ddns'):
        alerted.touch()


@click.command()
@click.option('--dryrun', '-d', is_flag=True, help='Report, but do not change Route53.')
@click.option('--forceupdate', '-f', is_flag=True, help='Update Route53 even if it matches.')
def main(dryrun, forceupdate):
    try:
        ip = find_external_ip(SOURCES)
        log(f'External IP is {ip}')
        update_route53(ip, dryrun, forceupdate)
        ok = True
    except Exception:
        traceback.print_exc()
        ok = False
    if 'STATE_DIRECTORY' in os.environ and not dryrun:
        record_outcome(Path(os.environ['STATE_DIRECTORY']), ok, time.time(), escalate)
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
