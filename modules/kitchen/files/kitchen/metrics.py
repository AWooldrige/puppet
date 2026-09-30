#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
import logging
import socket
import time
from contextlib import contextmanager

log = logging.getLogger("kitchen.metrics")

DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 8094
DEFAULT_MEASUREMENT = "kitchen"


class Metrics:
    def __init__(self, enabled=True, host=DEFAULT_HOST, port=DEFAULT_PORT,
                 measurement=DEFAULT_MEASUREMENT):
        self.enabled = enabled
        self.host = host
        self.port = port
        self.measurement = measurement

    @classmethod
    def from_config(cls, config):
        m = config.get("metrics", {})
        return cls(
            enabled=m.get("enabled", True),
            host=m.get("host", DEFAULT_HOST),
            port=m.get("port", DEFAULT_PORT),
            measurement=m.get("measurement", DEFAULT_MEASUREMENT),
        )

    @staticmethod
    def _escape_tag(value):
        return (str(value).replace("\\", "\\\\").replace(",", "\\,")
                .replace(" ", "\\ ").replace("=", "\\="))

    def _line(self, field, value, tags):
        tag_str = "".join(
            f",{self._escape_tag(k)}={self._escape_tag(v)}"
            for k, v in sorted((tags or {}).items())
        )
        if isinstance(value, bool):
            value = 1 if value else 0
        return f"{self.measurement}{tag_str} {field}={value}"

    def send(self, field, value, tags=None):
        if not self.enabled:
            return
        line = self._line(field, value, tags)
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            try:
                sock.sendto(line.encode("utf-8"), (self.host, self.port))
            finally:
                sock.close()
        except OSError as exc:  # pragma: no cover
            log.debug("metric send failed (%s): %s", exc, line)

    @contextmanager
    def timer(self, field, tags=None):
        start = time.monotonic()
        try:
            yield
        finally:
            self.send(field, round(time.monotonic() - start, 3), tags)


class NullMetrics(Metrics):
    def __init__(self):
        super().__init__(enabled=False)

    def send(self, field, value, tags=None):
        return
