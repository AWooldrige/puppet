#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
"""
Blank and unblank the Touch Display 2 panel.

Two sysfs attributes, both documented stable kernel ABI:
  bl_power    0 = FB_BLANK_UNBLANK, 4 = FB_BLANK_POWERDOWN
  brightness  0 .. max_brightness

raspi::touchdisplay chgrp's those two files to the paneltouch group.
"""

import glob
import logging
import os

log = logging.getLogger("kitchen.backlight")

BL_POWER_ON = 0
BL_POWER_OFF = 4


class Backlight:
    def __init__(self, cfg):
        self.device_glob = cfg["backlight"]["device_glob"]
        self._device = None
        self._max_brightness = None
        self._warned_missing = False

    @property
    def available(self):
        return self.device() is not None

    def device(self):
        if self._device is not None:
            return self._device
        matches = sorted(glob.glob(self.device_glob))
        if not matches:
            # A miss is not cached. The flag only stops the warning repeating on every tick.
            if not self._warned_missing:
                log.warning("no backlight matching %s; screen control will do "
                            "nothing until one appears", self.device_glob)
                self._warned_missing = True
            return None
        self._device = matches[0]
        self._warned_missing = False
        if len(matches) > 1:
            log.warning("%d backlights match %s, using %s",
                        len(matches), self.device_glob, self._device)
        return self._device

    def max_brightness(self):
        if self._max_brightness is not None:
            return self._max_brightness
        value = self._read("max_brightness")
        if value is None:
            return None
        self._max_brightness = value
        return value

    def set_on(self, on):
        """
        Returns True when the panel state was changed.
        """
        if not self.available:
            return False

        if on:
            # Set brightness before unblanking,
            maximum = self.max_brightness()
            if maximum:
                self._write("brightness", maximum)
            ok = self._write("bl_power", BL_POWER_ON)
        else:
            ok = self._write("bl_power", BL_POWER_OFF)

        if ok:
            log.info("panel %s", "on" if on else "off")
        return ok

    def _path(self, attribute):
        device = self.device()
        return os.path.join(device, attribute) if device else None

    def _read(self, attribute):
        path = self._path(attribute)
        if path is None:
            return None
        try:
            with open(path, "r", encoding="ascii") as handle:
                return int(handle.read().strip())
        except (OSError, ValueError):
            log.warning("could not read %s", path)
            return None

    def _write(self, attribute, value):
        path = self._path(attribute)
        if path is None:
            return False
        try:
            with open(path, "w", encoding="ascii") as handle:
                handle.write(str(value))
            return True
        except OSError:
            # Usually a permissions problem, meaning the udev rule or the paneltouch
            # group membership has not applied.
            log.error("could not write %s=%s (paneltouch group?)", path, value)
            return False
