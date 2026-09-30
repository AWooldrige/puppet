#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
"""
Test package.

Several tests deliberately drive failure paths and log with exc_info. Without a
handler Python's lastResort logger dumps the tracebacks to stderr and a passing run
looks broken, so mute the package logger here.
"""

import logging

logging.getLogger("kitchen").addHandler(logging.NullHandler())
logging.getLogger("kitchen").propagate = False
