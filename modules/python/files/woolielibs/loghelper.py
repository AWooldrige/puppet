import sys
import logging
from logging.handlers import SysLogHandler
from os import getpid

LOG_FORMAT = "%(levelname)s: %(message)s"

def bootstrap_logger(name):
    l = logging.getLogger(name)
    l.setLevel(logging.DEBUG)

    #Catchall for all uncaught Exceptions
    def handleUncaughtException(excType, excValue, traceback):
        l.error("Uncaught exception", exc_info=(excType, excValue, traceback))
    sys.excepthook = handleUncaughtException

    prefix = "{0}[{1}] ".format(name, str(getpid()))

    #Console handler
    ch = logging.StreamHandler()
    ch.setLevel(logging.DEBUG)
    ch.setFormatter(logging.Formatter(prefix + LOG_FORMAT))
    l.addHandler(ch)

    #Syslog handler
    sh = SysLogHandler(address='/dev/log')
    sh.setLevel(logging.DEBUG)
    sh.setFormatter(logging.Formatter(prefix + LOG_FORMAT))
    l.addHandler(sh)

    l.debug("Starting {0} script.".format(name))
    return l
