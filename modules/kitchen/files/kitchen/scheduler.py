#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
"""
The rules, in the order they are applied:

1. A manual "screen off" wins until something is touched.
2. Inside the scheduled hours the panel is on.
3. Outside them it is off, unless it was woken by a touch, in which case it stays
   on until it has been idle for overnight_hold_minutes.
"""

BOARD_PAGE = "board"


def in_scheduled_hours(now, on_hour, off_hour):
    return on_hour <= now.hour < off_hour


def seconds_since(now, moment):
    if moment is None:
        return None
    return (now - moment).total_seconds()


def screen_should_be_on(now, last_activity, manual_off_at, on_hour, off_hour,
                        overnight_hold_minutes):
    """
    last_activity   when the touchscreen (or the shell) last saw something
    manual_off_at   when "Screen off" was last tapped, or None
    """
    if manual_off_at is not None:
        since_request = seconds_since(now, manual_off_at)
        activity_after_request = (
            last_activity is not None and last_activity > manual_off_at)
        if since_request is not None and since_request >= 0 \
                and not activity_after_request:
            return False

    if in_scheduled_hours(now, on_hour, off_hour):
        return True

    idle = seconds_since(now, last_activity)
    if idle is None:
        return False
    return idle < overnight_hold_minutes * 60


def should_revert_to_board(active_page, now, last_activity,
                           revert_after_seconds):
    """
    Whether a non-board tab has been idle long enough to be dropped.
    rather than the page.
    """
    if active_page == BOARD_PAGE:
        return False
    idle = seconds_since(now, last_activity)
    if idle is None:
        # No touch has ever been recorded, so return to the board.
        return True
    return idle >= revert_after_seconds
