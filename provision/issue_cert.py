#!/usr/bin/env python3
"""Issue a leaf certificate from the WooldrigePKI root CA."""

import argparse
import base64
import datetime
import os
import secrets
import stat
import subprocess
import sys
import tempfile
from pathlib import Path

import yaml
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ed25519, rsa
from cryptography.hazmat.primitives.serialization import pkcs12
from cryptography.x509.oid import ExtendedKeyUsageOID, NameOID

from provision import REPO, Error, load_yaml

ROOT_CERTIFICATE = REPO / 'modules/base/files/WooldrigePKI_root_CA_1.certificate.pem'
VALIDITY_DAYS = 365 * 20
UNITS = {'d': 'desktop', 's': 'server', 'm': 'mobile'}

# Typed on a phone keyboard, so no punctuation and nothing easily misread.
PASSWORD_ALPHABET = 'abcdefghjkmnpqrstuvwxyz23456789'


def unit(hostname):
    # hplaptop2 predates the naming convention and has no type character.
    return UNITS.get(hostname[3:4], 'desktop')


def is_mobile(hostname):
    return unit(hostname) == 'mobile'


def subject(hostname):
    return x509.Name([
        x509.NameAttribute(NameOID.ORGANIZATION_NAME, 'WooldrigePKI'),
        x509.NameAttribute(NameOID.ORGANIZATIONAL_UNIT_NAME, unit(hostname)),
        x509.NameAttribute(NameOID.COMMON_NAME, hostname),
    ])


def load_ca_key(path):
    text = Path(path).read_text()
    if not text.lstrip().startswith('-----BEGIN'):
        text = load_yaml(path)['root_ca_private_key']
    return serialization.load_pem_private_key(text.encode(), password=None)


def build(hostname, key, ca_certificate, ca_key, server):
    now = datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0)
    purposes = [ExtendedKeyUsageOID.CLIENT_AUTH]
    if server:
        purposes.append(ExtendedKeyUsageOID.SERVER_AUTH)

    builder = x509.CertificateBuilder() \
        .subject_name(subject(hostname)) \
        .issuer_name(ca_certificate.subject) \
        .public_key(key.public_key()) \
        .serial_number(secrets.randbits(128)) \
        .not_valid_before(now) \
        .not_valid_after(now + datetime.timedelta(days=VALIDITY_DAYS)) \
        .add_extension(x509.BasicConstraints(ca=False, path_length=None), critical=True) \
        .add_extension(x509.SubjectKeyIdentifier.from_public_key(key.public_key()), False) \
        .add_extension(
            x509.AuthorityKeyIdentifier.from_issuer_public_key(ca_certificate.public_key()),
            False) \
        .add_extension(x509.KeyUsage(
            digital_signature=True, content_commitment=False,
            key_encipherment=isinstance(key, rsa.RSAPrivateKey), data_encipherment=False,
            key_agreement=False, key_cert_sign=False, crl_sign=False,
            encipher_only=False, decipher_only=False), False) \
        .add_extension(x509.ExtendedKeyUsage(purposes), False)

    if server:
        builder = builder.add_extension(x509.SubjectAlternativeName([
            x509.DNSName(hostname),
            x509.DNSName(f'{hostname}.h.wooldrige.co.uk'),
            x509.DNSName(f'{hostname}.local'),
        ]), False)

    return builder.sign(ca_key, None if isinstance(ca_key, ed25519.Ed25519PrivateKey)
                        else hashes.SHA256())


def pem(certificate):
    return certificate.public_bytes(serialization.Encoding.PEM).decode()


def key_pem(key):
    return key.private_bytes(serialization.Encoding.PEM,
                             serialization.PrivateFormat.PKCS8,
                             serialization.NoEncryption()).decode()


def bundle_for(hostname, key, certificate, ca_certificate, password, legacy):
    if legacy:
        encryption = serialization.PrivateFormat.PKCS12.encryption_builder() \
            .key_cert_algorithm(pkcs12.PBES.PBESv1SHA1And3KeyTripleDESCBC) \
            .hmac_hash(hashes.SHA1()).build(password.encode())
    else:
        encryption = serialization.BestAvailableEncryption(password.encode())
    return pkcs12.serialize_key_and_certificates(
        hostname.encode(), key, certificate, [ca_certificate], encryption)


def issue(hostname, ca_key_path, ca_certificate_path=ROOT_CERTIFICATE, key_type=None,
          server=False, legacy=False):
    key_type = key_type or ('rsa' if is_mobile(hostname) else 'ed25519')
    if is_mobile(hostname) and key_type != 'rsa':
        raise Error(f'{hostname} is a phone: no browser can present an ED25519 client '
                    'certificate, so it needs --key-type rsa')

    ca_certificate = x509.load_pem_x509_certificate(Path(ca_certificate_path).read_bytes())
    key = (rsa.generate_private_key(65537, 4096) if key_type == 'rsa'
           else ed25519.Ed25519PrivateKey.generate())
    certificate = build(hostname, key, ca_certificate, load_ca_key(ca_key_path), server)

    document = {'certificate': pem(certificate), 'private_key': key_pem(key)}
    password = None
    if is_mobile(hostname):
        password = ''.join(secrets.choice(PASSWORD_ALPHABET) for _ in range(20))
        bundle = bundle_for(hostname, key, certificate, ca_certificate, password, legacy)
        document['pkcs12_base64'] = base64.b64encode(bundle).decode()
        document['pkcs12_password'] = password
    return certificate, document


def verify(certificate, ca_certificate_path):
    with tempfile.TemporaryDirectory() as scratch:
        path = Path(scratch) / 'leaf.pem'
        path.write_text(pem(certificate))
        result = subprocess.run(
            ['openssl', 'verify', '-CAfile', str(ca_certificate_path),
             '-purpose', 'sslclient', str(path)], capture_output=True, text=True)
        if result.returncode != 0:
            raise Error(f'the new certificate does not verify: {result.stdout}')


def write_private(path, data):
    handle = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, stat.S_IRUSR | stat.S_IWUSR)
    with os.fdopen(handle, 'wb' if isinstance(data, bytes) else 'w') as stream:
        stream.write(data)


def encrypt(path):
    """
    sops finds .sops.yaml by walking up from the working directory, not from the
    file, so run it inside the store's own directory.

    A failure deletes the plaintext. It holds a private key, and the store lives in
    a synced repo, so leaving it behind is worse than losing the certificate.
    """
    result = subprocess.run(['sops', '--encrypt', '--in-place', path.name],
                            cwd=path.parent, capture_output=True, text=True)
    if result.returncode != 0:
        path.unlink(missing_ok=True)
        detail = result.stderr.strip().splitlines()
        raise Error(f'sops could not encrypt {path.name}: '
                    f'{detail[-1] if detail else result.returncode}. '
                    'The plaintext has been deleted, so nothing was stored.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('hostname')
    parser.add_argument('--ca-key', required=True)
    parser.add_argument('--ca-cert', default=str(ROOT_CERTIFICATE))
    parser.add_argument('--store', required=True)
    parser.add_argument('--p12-out')
    parser.add_argument('--key-type', choices=('ed25519', 'rsa'))
    parser.add_argument('--server', action='store_true')
    parser.add_argument('--legacy-p12', action='store_true')
    parser.add_argument('--no-encrypt', action='store_true')
    parser.add_argument('--force', action='store_true')
    args = parser.parse_args()

    store = Path(args.store)
    try:
        if store.exists() and not args.force:
            raise Error(f'{store} exists: a host keeps its certificate across a re-flash, '
                        'so re-provision from it rather than issuing a second one')

        certificate, document = issue(args.hostname, args.ca_key, args.ca_cert,
                                      args.key_type, args.server, args.legacy_p12)
        verify(certificate, args.ca_cert)

        store.parent.mkdir(parents=True, exist_ok=True)
        write_private(store, yaml.safe_dump(document, default_flow_style=False))
        if not args.no_encrypt:
            encrypt(store)
        if args.p12_out:
            if 'pkcs12_base64' not in document:
                raise Error(f'--p12-out applies to a mobile host, {args.hostname} is not one')
            write_private(args.p12_out, base64.b64decode(document['pkcs12_base64']))
    except Error as error:
        print(f'ERROR: {error}', file=sys.stderr)
        return 2

    print(certificate.subject.rfc4514_string())
    print(f'  {store}')
    if args.p12_out:
        print(f'  {args.p12_out}, password {document["pkcs12_password"]}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
