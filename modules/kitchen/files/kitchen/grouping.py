#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
"""Bucket occurrences into: This week (..Fri), This weekend, Next week, Later."""

import datetime as dt

THIS_WEEK = "This week"
THIS_WEEKEND = "This weekend"
NEXT_WEEK = "Next week"
FUTURE = "Later"

SECTION_ORDER = [THIS_WEEK, THIS_WEEKEND, NEXT_WEEK, FUTURE]


def _anchors(today):
    weekday = today.weekday()  # Mon=0 .. Sun=6
    monday_this = today - dt.timedelta(days=weekday)
    return {
        "friday_this": monday_this + dt.timedelta(days=4),
        "saturday_this": monday_this + dt.timedelta(days=5),
        "sunday_this": monday_this + dt.timedelta(days=6),
        "monday_next": monday_this + dt.timedelta(days=7),
        "sunday_next": monday_this + dt.timedelta(days=13),
    }


def section_for(day, today):
    if day < today:
        return None
    a = _anchors(today)
    if day <= a["friday_this"]:
        return THIS_WEEK
    if a["saturday_this"] <= day <= a["sunday_this"]:
        return THIS_WEEKEND
    if a["monday_next"] <= day <= a["sunday_next"]:
        return NEXT_WEEK
    return FUTURE


def group(occurrences, today):
    """Ordered [(section, [occ])] for non-empty sections; input pre-sorted."""
    buckets = {name: [] for name in SECTION_ORDER}
    for occ in occurrences:
        section = section_for(occ.day, today)
        if section is not None:
            buckets[section].append(occ)
    return [(name, buckets[name]) for name in SECTION_ORDER if buckets[name]]
