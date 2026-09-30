#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
"""
Log to syslog (journalctl -t kitchen) and stdout.
"""

import logging
import logging.handlers
import sys

DEFAULT_TAG = "kitchen"


def configure(tag=DEFAULT_TAG, level=logging.INFO):
    logger = logging.getLogger("kitchen")
    logger.setLevel(level)
    if getattr(logger, "_kitchen_configured", False):
        return logger

    fmt = logging.Formatter(tag + "[%(process)d]: %(name)s %(message)s")
    stream_handler = logging.StreamHandler(sys.stdout)
    stream_handler.setFormatter(fmt)
    logger.addHandler(stream_handler)
    try:
        syslog_handler = logging.handlers.SysLogHandler(address="/dev/log")
        syslog_handler.setFormatter(fmt)
        logger.addHandler(syslog_handler)
    except (OSError, IOError):
        logger.warning("syslog socket /dev/log unavailable; stdout only")

    logger._kitchen_configured = True
    return logger
