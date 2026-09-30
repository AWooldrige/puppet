#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
import datetime as dt
import logging
from dataclasses import dataclass
from typing import Optional

try:
    from zoneinfo import ZoneInfo
except ImportError:  # pragma: no cover
    ZoneInfo = None

log = logging.getLogger("kitchen.calendar")

SCOPES = ["https://www.googleapis.com/auth/calendar.readonly"]
NODISP_MARKER = "NODISP"


@dataclass
class Occurrence:
    title: str
    day: dt.date          # first visible day (clamped to the window start)
    all_day: bool
    start_time: Optional[dt.time]
    end_time: Optional[dt.time]
    location: Optional[str]
    multi_day: bool
    end_day: Optional[dt.date] = None

    def __post_init__(self):
        if self.end_day is None:
            self.end_day = self.day

    def sort_key(self):
        t = self.start_time or dt.time(0, 0)
        return (self.day, 0 if (self.all_day or self.multi_day) else 1, t)


def has_nodisp(title):
    return NODISP_MARKER in (title or "")


def _tz(name):
    if ZoneInfo is None:
        return dt.timezone.utc
    try:
        return ZoneInfo(name)
    except Exception:
        return dt.timezone.utc


def _parse_bound(node, tzinfo):
    """Return (date, datetime_or_None, all_day) for a Google start/end node."""
    if "date" in node:
        return dt.date.fromisoformat(node["date"]), None, True
    moment = dt.datetime.fromisoformat(node["dateTime"])
    if moment.tzinfo is None:
        moment = moment.replace(tzinfo=tzinfo)
    moment = moment.astimezone(tzinfo)
    return moment.date(), moment, False


def expand_event(event, window_start, window_end, tzinfo):
    """One raw Google event -> [Occurrence] (0 or 1), clipped to the window."""
    title = " ".join((event.get("summary") or "").split()) or "(no title)"
    if has_nodisp(title):
        return []

    location = " ".join((event.get("location") or "").split()) or None
    start = event.get("start", {})
    end = event.get("end", {})
    if not start or not end:
        return []

    start_day, start_dt, all_day = _parse_bound(start, tzinfo)
    end_day, end_dt, _ = _parse_bound(end, tzinfo)

    if all_day:
        last_day = end_day - dt.timedelta(days=1)  # Google end date is exclusive
        start_time = end_time = None
    else:
        last_day = end_day
        if end_dt is not None and end_dt.time() == dt.time(0, 0) \
                and end_day > start_day:
            last_day = end_day - dt.timedelta(days=1)
        start_time = start_dt.time() if start_dt else None
        end_time = end_dt.time() if end_dt else None

    if last_day < start_day:
        last_day = start_day
    if last_day < window_start or start_day > window_end:
        return []

    visible_start = max(start_day, window_start)
    multi_day = last_day > visible_start

    return [Occurrence(
        title=title,
        day=visible_start,
        end_day=last_day,
        all_day=all_day,
        start_time=start_time if (not all_day and not multi_day) else None,
        end_time=end_time if (not all_day and not multi_day) else None,
        location=location,
        multi_day=multi_day,
    )]


def normalise_events(raw_events, window_start, window_end, tzinfo):
    out = []
    for event in raw_events:
        out.extend(expand_event(event, window_start, window_end, tzinfo))
    out.sort(key=Occurrence.sort_key)
    return out


def _build_service(service_account_file):
    from google.oauth2 import service_account
    from googleapiclient.discovery import build

    creds = service_account.Credentials.from_service_account_file(
        service_account_file, scopes=SCOPES)
    return build("calendar", "v3", credentials=creds, cache_discovery=False)


def _fetch_raw(service, calendar_id, time_min, time_max):
    events = []
    page_token = None
    while True:
        resp = service.events().list(
            calendarId=calendar_id,
            timeMin=time_min,
            timeMax=time_max,
            singleEvents=True,
            orderBy="startTime",
            maxResults=250,
            pageToken=page_token,
        ).execute()
        events.extend(resp.get("items", []))
        page_token = resp.get("nextPageToken")
        if not page_token:
            break
    return events


def fetch_occurrences(cfg, metrics=None, now=None):
    cal = cfg["calendar"]
    tzinfo = _tz(cal["timezone"])
    now = now or dt.datetime.now(tzinfo)
    window_start = now.date()
    window_end = window_start + dt.timedelta(days=cal["lookahead_days"])

    time_min = now.isoformat()
    time_max = (now + dt.timedelta(days=cal["lookahead_days"])).isoformat()

    service = _build_service(cal["service_account_file"])
    raw = []
    for calendar_id in cal["calendar_ids"]:
        try:
            items = _fetch_raw(service, calendar_id, time_min, time_max)
            raw.extend(items)
            if metrics:
                metrics.send("calendar_events_raw", len(items),
                             {"calendar": calendar_id})
        except Exception:
            log.error("failed fetching calendar %s", calendar_id, exc_info=True)
            if metrics:
                metrics.send("calendar_fetch_error", 1, {"calendar": calendar_id})

    occurrences = normalise_events(raw, window_start, window_end, tzinfo)
    if metrics:
        metrics.send("calendar_occurrences", len(occurrences))
    return occurrences
