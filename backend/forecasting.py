from __future__ import annotations

import calendar
from datetime import date
from typing import List, Dict, Any


def _add_months(d: date, months: int) -> date:
    m = d.month - 1 + months
    y = d.year + m // 12
    m = m % 12 + 1
    day = min(d.day, calendar.monthrange(y, m)[1])
    return date(y, m, day)


def make_next_quarter_ends(last_period_end: str, steps: int = 4) -> List[str]:
    # last_period_end: "YYYY-MM-DD"
    y, m, d = map(int, last_period_end.split("-"))
    last = date(y, m, d)
    out = []
    cur = last
    for _ in range(steps):
        cur = _add_months(cur, 3)
        out.append(cur.isoformat())
    return out


def naive_forecast(history: List[Dict[str, Any]], steps: int = 4) -> List[Dict[str, Any]]:
    """
    history items: [{"period_end":"YYYY-MM-DD","value":float}, ...] in chronological order
    """
    if not history:
        return []

    last_date = history[-1]["period_end"]
    future_dates = make_next_quarter_ends(last_date, steps=steps)

    # Simple trend from last 4 qtrs (median growth-ish)
    vals = [h["value"] for h in history if h.get("value") is not None]
    if len(vals) < 2:
        g = 0.0
        last_val = vals[-1] if vals else 0.0
    else:
        last_val = vals[-1]
        prev = vals[-2]
        g = 0.0 if prev == 0 else (last_val / prev - 1.0)

    out = []
    cur = float(last_val)
    for i, dt in enumerate(future_dates, start=1):
        cur = cur * (1.0 + g)  # extrapolate
        yhat = cur
        p10 = yhat * 0.90
        p90 = yhat * 1.10
        out.append({"period_end": dt, "yhat": float(yhat), "p10": float(p10), "p90": float(p90)})

    return out
