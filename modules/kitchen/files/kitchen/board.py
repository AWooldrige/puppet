#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
import datetime as dt
import logging
import socket

from . import bank_holidays as bank_holidays_mod
from . import calendar_source
from . import status as status_mod
from . import weather as weather_mod

log = logging.getLogger("kitchen.board")


def _range_text(occ):
    return f"{occ.first_day:%a %-d %b} to {occ.end_day:%a %-d %b}"


def _time_text(occ):
    if occ.multi_day:
        return _range_text(occ)
    if not occ.all_day and occ.start_time is not None:
        if occ.end_time is not None:
            return f"{occ.start_time:%H:%M} to {occ.end_time:%H:%M}"
        return f"{occ.start_time:%H:%M}"
    return "All day"


def _continues(occ, day):
    if not occ.multi_day:
        return None
    if day == occ.first_day:
        return "first"
    if day == occ.end_day:
        return "last"
    return "middle"


def occurrence_to_dict(occ, day):
    return {
        "title": occ.title,
        "location": occ.location,
        "all_day": occ.all_day,
        "multi_day": occ.multi_day,
        "continues": _continues(occ, day),
        "start_time": occ.start_time.strftime("%H:%M") if occ.start_time else None,
        "end_time": occ.end_time.strftime("%H:%M") if occ.end_time else None,
        "time_text": _time_text(occ),
    }


def _day_weather(forecast):
    return {
        "description": forecast["description"],
        "temp_max": forecast["temp_max"],
        "temp_min": forecast["temp_min"],
        "precip_chance": forecast["precip_chance"],
        "uv_text": (f"UV {round(forecast['uv_max'])} "
                    f"{weather_mod.uv_category(round(forecast['uv_max']))}"
                    if forecast["uv_max"] is not None else None),
    }


def build_days(occurrences, today, count, holidays, weather):
    forecasts = {f["date"]: f for f in (weather or {}).get("days", [])}
    days = []
    for offset in range(count):
        day = today + dt.timedelta(days=offset)
        iso = day.isoformat()
        events = [occurrence_to_dict(occ, day) for occ in occurrences
                  if occ.day <= day <= occ.end_day]
        events.sort(key=lambda e: (not e["multi_day"], not e["all_day"],
                                   e["start_time"] or ""))
        days.append({
            "date": iso,
            "weekday_text": day.strftime("%a"),
            "day_number": day.day,
            "day_text": day.strftime("%-d %b"),
            "is_today": offset == 0,
            "is_weekend": day.weekday() >= 5,
            "is_week_start": day.weekday() == 0,
            "bank_holiday": holidays.get(iso),
            "weather": _day_weather(forecasts[iso]) if iso in forecasts else None,
            "events": events,
        })
    return days


def check_upstream(cfg):
    health = cfg["health"]
    try:
        with socket.create_connection(
                (health["upstream_host"], health["upstream_port"]),
                timeout=health["check_timeout_seconds"]):
            return True
    except OSError:
        return False


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

    holidays = bank_holidays_mod.fetch(cfg, metrics)
    days = build_days(occurrences, today, cfg["calendar"]["lookahead_days"],
                      holidays, weather)
    upstream_ok = check_upstream(cfg)

    payload = {
        "generated_at": now.timestamp(),
        "days": days,
        "event_count": len(occurrences),
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
        wifi = status_mod.wifi_percent()
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
