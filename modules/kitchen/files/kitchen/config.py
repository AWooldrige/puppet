#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
import tomllib

DEFAULT_PATH = "/etc/kitchen/config.toml"


def load(path=DEFAULT_PATH):
    with open(path, "rb") as handle:
        return tomllib.load(handle)


def loads(text):
    return tomllib.loads(text)
