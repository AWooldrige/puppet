import logging
from logging.handlers import SysLogHandler
from os import getpid

LOG_FORMAT = "%(levelname)s: %(message)s"

def bootstrap_logger(name):
    l = logging.getLogger(name)
    l.setLevel(logging.DEBUG)

    #Console handler
    ch = logging.StreamHandler()
    ch.setLevel(logging.DEBUG)
    ch.setFormatter(logging.Formatter(LOG_FORMAT))
    l.addHandler(ch)

    #Syslog handler
    sh = SysLogHandler(address='/dev/log')
    sh.setLevel(logging.DEBUG)
    prefix = "{0}[{1}] ".format(name.upper(), str(getpid()))
    sh.setFormatter(logging.Formatter(prefix + LOG_FORMAT))
    l.addHandler(sh)

    return l
