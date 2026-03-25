from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Dict, List, Tuple, Any


@dataclass
class SanityResult:
    ok: bool
    warnings: List[str]
    cleaned: Dict[str, List[Dict[str, Any]]]  # {"revenue":[...], "net_income":[...]}


def _parse_date(s: str) -> datetime:
    return datetime.fromisoformat(s[:10])


def sanity_check_income_statement(items: List[Dict[str, Any]], want_points: int = 16) -> SanityResult:
    warnings: List[str] = []
    cleaned = {"revenue": [], "net_income": []}

    if not items:
        return SanityResult(False, ["FMP income statement returned empty list."], cleaned)

    # Log available field names from the first record for debugging
    if items:
        sample_keys = list(items[0].keys())
        print(f"DEBUG sanity: FMP income-statement fields = {sample_keys}")

    # FMP usually returns newest first; normalize to oldest->newest
    usable = []
    for r in items:
        d = r.get("date")
        # Robust field resolution: try camelCase then snake_case variants
        rev = r.get("revenue") or r.get("totalRevenue") or r.get("total_revenue")
        ni = r.get("netIncome") or r.get("net_income")
        if not d:
            continue
        usable.append((d, rev, ni))

    usable.sort(key=lambda x: _parse_date(x[0]))

    if len(usable) < 8:
        warnings.append(f"Only {len(usable)} quarterly points available (< 8). Forecast quality is limited.")

    # Keep last N points (most recent)
    if len(usable) >= want_points:
        usable = usable[-want_points:]
    else:
        warnings.append(f"Only {len(usable)} quarterly points available (< {want_points}).")

    # Build series
    missing_rev = 0
    missing_ni = 0

    for d, rev, ni in usable:
        if rev is None:
            missing_rev += 1
        else:
            cleaned["revenue"].append({"period_end": d[:10], "value": float(rev)})

        if ni is None:
            missing_ni += 1
        else:
            cleaned["net_income"].append({"period_end": d[:10], "value": float(ni)})

    if missing_rev:
        warnings.append(f"Revenue missing for {missing_rev} quarters.")
    if missing_ni:
        warnings.append(f"Net income missing for {missing_ni} quarters.")

    ok = len(cleaned["revenue"]) >= 4 and len(cleaned["net_income"]) >= 4
    if not ok:
        warnings.append("Not enough clean points to forecast reliably (need >=4).")

    return SanityResult(ok=ok, warnings=warnings, cleaned=cleaned)
