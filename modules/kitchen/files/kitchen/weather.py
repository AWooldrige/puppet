#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
import json
import logging
import os
import time

log = logging.getLogger("kitchen.weather")

_ENDPOINT = "https://api.open-meteo.com/v1/forecast"
_CACHE_NAME = "weather_cache.json"
_DAILY_FIELDS = (
    "weather_code,temperature_2m_max,temperature_2m_min,uv_index_max,"
    "precipitation_probability_max"
)

# WMO weather codes to short labels.
_CODE_GROUPS = [
    ({0}, "Clear"),
    ({1, 2}, "Sunny spells"),
    ({3}, "Cloudy"),
    ({45, 48}, "Fog"),
    ({51, 53, 55, 56, 57}, "Drizzle"),
    ({61, 63, 65, 66, 67}, "Rain"),
    ({80, 81, 82}, "Showers"),
    ({71, 73, 75, 77, 85, 86}, "Snow"),
    ({95, 96, 99}, "Storms"),
]


def describe(code):
    for codes, label in _CODE_GROUPS:
        if code in codes:
            return label
    return "Mixed"


def uv_category(uv):
    if uv < 3:
        return "Low"
    if uv < 6:
        return "Moderate"
    if uv < 8:
        return "High"
    if uv < 11:
        return "Very High"
    return "Extreme"


def _cache_path(cfg):
    return os.path.join(cfg["state"]["dir"], _CACHE_NAME)


def _read_cache(cfg):
    try:
        with open(_cache_path(cfg), "r", encoding="utf-8") as handle:
            return json.load(handle)
    except (OSError, ValueError):
        return None


def _write_cache(cfg, data):
    try:
        with open(_cache_path(cfg), "w", encoding="utf-8") as handle:
            json.dump({"ts": time.time(), "data": data}, handle)
    except OSError:
        log.debug("could not write weather cache")


def parse_daily(daily, forecast_days):
    dates = daily["time"][:forecast_days]

    days = [{
        "date": dates[i],
        "description": describe(daily["weather_code"][i]),
        "temp_max": daily["temperature_2m_max"][i],
        "temp_min": daily["temperature_2m_min"][i],
        "uv_max": daily["uv_index_max"][i],
        "precip_chance": daily["precipitation_probability_max"][i],
    } for i in range(len(dates))]

    if not days:
        raise ValueError("Open-Meteo returned no daily entries")

    today = days[0]
    return {
        "description": today["description"],
        "temp_max": today["temp_max"],
        "temp_min": today["temp_min"],
        "uv_max": today["uv_max"],
        "precip_chance": today["precip_chance"],
        "days": days,
    }


def fetch_weather(cfg, metrics=None):
    w = cfg["weather"]
    ttl = w["cache_minutes"] * 60
    forecast_days = w["forecast_days"]

    cached = _read_cache(cfg)
    if cached and (time.time() - cached.get("ts", 0) < ttl):
        return cached["data"]

    import requests
    params = {
        "latitude": w["latitude"],
        "longitude": w["longitude"],
        "daily": _DAILY_FIELDS,
        "timezone": w["timezone"],
        "forecast_days": forecast_days,
    }
    try:
        resp = requests.get(_ENDPOINT, params=params, timeout=10)
        resp.raise_for_status()
        result = parse_daily(resp.json()["daily"], forecast_days)
        _write_cache(cfg, result)
        if metrics:
            metrics.send("weather_success", 1)
            metrics.send("weather_stale", 0)
            for field in ("temp_max", "temp_min", "uv_max"):
                if result[field] is not None:
                    metrics.send(f"weather_{field}", result[field])
        return result
    except Exception:
        log.error("weather fetch failed", exc_info=True)
        if metrics:
            metrics.send("weather_success", 0)
        max_stale = w["max_stale_hours"] * 3600
        if cached and (time.time() - cached.get("ts", 0) < max_stale):
            if metrics:
                metrics.send("weather_stale", 1)
            return cached["data"]
        return None


_SEP = "   \u00b7   "


def format_line(weather):
    if not weather:
        return _SEP.join(["Today", "Weather --", "Low --\u00b0 High --\u00b0",
                          "UV --"])
    lo, hi, uv = weather.get("temp_min"), weather.get("temp_max"), weather.get("uv_max")
    lo_str = f"{round(lo)}\u00b0" if lo is not None else "--\u00b0"
    hi_str = f"{round(hi)}\u00b0" if hi is not None else "--\u00b0"
    uv_str = f"UV {round(uv)} {uv_category(round(uv))}" if uv is not None else "UV --"
    return _SEP.join(["Today", weather["description"],
                      f"Low {lo_str} High {hi_str}", uv_str])

