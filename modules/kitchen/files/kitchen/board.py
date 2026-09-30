#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
import datetime as dt
import logging
import socket

from . import calendar_source
from . import grouping
from . import status as status_mod
from . import weather as weather_mod

log = logging.getLogger("kitchen.board")


def _time_text(occ):
    """
    Label shown on the right of an event row.
    """
    if occ.multi_day:
        return "\u2192 " + occ.end_day.strftime("%-d %b")
    if not occ.all_day and occ.start_time is not None:
        if occ.end_time is not None:
            return f"{occ.start_time:%H:%M}\u2013{occ.end_time:%H:%M}"
        return f"{occ.start_time:%H:%M}"
    return "All day" if occ.all_day else ""


def occurrence_to_dict(occ, today):
    """
    Convert an Occurrence into a JSON-safe event the frontend can render directly.

    """
    return {
        # Stable enough to key DOM nodes and to match a tapped row back to its
        # event; not a Google id, which we deliberately don't carry around.
        "id": f"{occ.day.isoformat()}|{occ.start_time or ''}|{occ.title}",
        "title": occ.title,
        "day": occ.day.isoformat(),
        "day_text": occ.day.strftime("%-d %b"),
        "weekday_text": occ.day.strftime("%a"),
        "end_day": occ.end_day.isoformat(),
        "all_day": occ.all_day,
        "multi_day": occ.multi_day,
        "start_time": occ.start_time.strftime("%H:%M") if occ.start_time else None,
        "end_time": occ.end_time.strftime("%H:%M") if occ.end_time else None,
        "time_text": _time_text(occ),
        "location": occ.location,
        "is_today": occ.day == today,
    }


def _next_event(today_events, now):
    """
    Return the next timed event today, or the first all-day one if there is none.
    """
    current = now.strftime("%H:%M")
    for event in today_events:
        if event["start_time"] and event["start_time"] >= current:
            return event
    for event in today_events:
        if event["all_day"] or event["multi_day"]:
            return event
    return None


def check_upstream(cfg):
    health = cfg["health"]
    try:
        with socket.create_connection(
                (health["upstream_host"], health["upstream_port"]),
                timeout=health["check_timeout_seconds"]):
            return True
    except OSError:
        return False


def build_status(cfg, now):
    return {
        "updated_text": now.strftime("%H:%M"),
        "next_refresh_text": status_mod.next_refresh(cfg, now),
        "wifi_percent": status_mod.wifi_percent(),
        "load_average": status_mod.load_average(),
    }


def build(cfg, state, metrics=None, now=None):
    tzinfo = calendar_source._tz(cfg["calendar"]["timezone"])
    now = now or dt.datetime.now(tzinfo)
    today = now.date()

    calendar_ok = True
    occurrences = []
    try:
        if metrics:
            with metrics.timer("calendar_fetch_seconds"):
                occurrences = calendar_source.fetch_occurrences(
                    cfg, metrics, now=now)
        else:
            occurrences = calendar_source.fetch_occurrences(cfg, now=now)
    except Exception:
        log.error("could not load calendar events", exc_info=True)
        calendar_ok = False
        if metrics:
            metrics.send("calendar_load_error", 1)

    sections = []
    for name, occs in grouping.group(occurrences, today):
        sections.append({
            "name": name,
            "events": [occurrence_to_dict(occ, today) for occ in occs],
        })

    today_events = [
        event
        for section in sections
        for event in section["events"]
        if event["is_today"]
    ]

    weather = None
    try:
        if metrics:
            with metrics.timer("weather_fetch_seconds"):
                weather = weather_mod.fetch_weather(cfg, metrics)
        else:
            weather = weather_mod.fetch_weather(cfg)
    except Exception:
        # fetch_weather handles its own errors
        log.error("weather lookup raised", exc_info=True)

    upstream_ok = check_upstream(cfg)

    payload = {
        "generated_at": now.timestamp(),
        "today": {
            "date": today.isoformat(),
            "date_text": today.strftime("%A %-d %B"),
            "weekday_text": today.strftime("%A"),
            "events": today_events,
            "event_count": len(today_events),
            "next_event": _next_event(today_events, now),
        },
        "sections": sections,
        "event_count": sum(len(s["events"]) for s in sections),
        "weather": {
            "available": weather is not None,
            "summary_text": weather_mod.format_line(weather),
            "today": weather,
            "days": (weather or {}).get("days", []),
        },
        "status": build_status(cfg, now),
        "health": {
            "calendar_ok": calendar_ok,
            "weather_ok": weather is not None,
            "upstream_ok": upstream_ok,
            "stale": False,
            "from_cache": False,
            "ok": calendar_ok and upstream_ok,
            "messages": _messages(calendar_ok, weather is not None, upstream_ok,
                                  stale=False),
        },
    }

    if metrics:
        metrics.send("calendar_ok", 1 if calendar_ok else 0)
        metrics.send("upstream_ok", 1 if upstream_ok else 0)
        metrics.send("events_shown", payload["event_count"])
        wifi = payload["status"]["wifi_percent"]
        if wifi is not None:
            metrics.send("wifi_percent", wifi)

    return payload


def _messages(calendar_ok, weather_ok, upstream_ok, stale):
    """
    Build the banner lines, most serious first.
    """
    messages = []
    if stale:
        messages.append("Calendar may be out of date")
    if not calendar_ok:
        messages.append("Cannot reach Google Calendar")
    if not upstream_ok:
        messages.append("Cannot reach the home server")
    if not weather_ok:
        messages.append("Weather unavailable")
    return messages


def stale_payload(cfg, state, now=None):
    """
    Return the last good snapshot, re-stamped and flagged, or None if there is none.
    """
    snapshot = state.load_snapshot()
    if snapshot is None:
        return None

    now = now or dt.datetime.now()
    snapshot["status"] = build_status(cfg, now)
    health = snapshot.setdefault("health", {})
    health["stale"] = state.is_stale(now)
    health["from_cache"] = True
    health["upstream_ok"] = check_upstream(cfg)
    health["ok"] = False
    health["messages"] = _messages(
        health.get("calendar_ok", False),
        health.get("weather_ok", False),
        health["upstream_ok"],
        stale=health["stale"],
    )
    if not health["messages"]:
        health["messages"] = ["Showing saved data"]
    return snapshot
