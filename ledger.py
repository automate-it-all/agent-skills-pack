#!/usr/bin/env python3
"""Skills-pack ledger: sums spend.jsonl + Stripe revenue, writes ledger.md.

Reads every run: spend.jsonl, revenue.jsonl, launch/posted.jsonl.
Writes: ledger.md, revenue.jsonl (new Stripe sales), KILLED on the kill line.
"""
import base64
import json
import os
import sys
import tempfile
import time
import urllib.request
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

DIR = Path(os.environ.get("LEDGER_DIR", Path(__file__).resolve().parent))
SPEND = DIR / "spend.jsonl"
REVENUE = DIR / "revenue.jsonl"
POSTED = DIR / "launch" / "posted.jsonl"
LEDGER_MD = DIR / "ledger.md"
KILLED = DIR / "KILLED"
KEY_FILE = Path.home() / ".config" / "stripe"
LAUNCH_PRICE, REGULAR_PRICE = 19, 39
KILL_DAYS, KILL_SALES = 90, 3


def read_jsonl(path):
    if not path.exists():
        return []
    out = []
    for line in path.read_text().splitlines():
        line = line.strip()
        if line:
            out.append(json.loads(line))
    return out


def stripe_key():
    try:
        key = KEY_FILE.read_text().strip()
    except OSError:
        return None
    return key or None


def stripe_charges(key):
    """All succeeded charges, oldest last. ponytail: 20 pages cap, fine for years."""
    out, start = [], None
    for _ in range(20):
        url = "https://api.stripe.com/v1/charges?limit=100"
        if start:
            url += "&starting_after=" + start
        req = urllib.request.Request(url)
        req.add_header("Authorization", "Basic "
                       + base64.b64encode((key + ":").encode()).decode())
        with urllib.request.urlopen(req, timeout=30) as r:
            body = json.load(r)
        for ch in body.get("data", []):
            if ch.get("status") == "succeeded":
                out.append(ch)
        if body.get("has_more") and body.get("data"):
            start = body["data"][-1]["id"]
        else:
            return out
    return out


def pull_sales(key):
    """Merge new Stripe sales into revenue.jsonl; return count added."""
    seen = {r.get("id") for r in read_jsonl(REVENUE)}
    new = []
    for ch in stripe_charges(key):
        if ch["id"] in seen:
            continue
        when = datetime.fromtimestamp(ch["created"], tz=timezone.utc).isoformat()
        new.append({
            "id": ch["id"],
            "date": when,
            "eur": round((ch["amount"] - ch.get("amount_refunded", 0)) / 100, 2),
            "currency": ch.get("currency", "?"),
        })
    if new:
        with REVENUE.open("a") as f:
            for row in new:
                f.write(json.dumps(row) + "\n")
    return len(new)


def launch_date():
    for row in read_jsonl(POSTED):
        d = row.get("date") if isinstance(row, dict) else None
        if d:
            return date.fromisoformat(str(d)[:10])
    return None


def euros(rows):
    return round(sum(r.get("eur", 0) for r in rows), 2)


def build(d=None):
    """Sum everything, enforce the kill line, write and return the report."""
    d = d or date.today()
    spend_rows = read_jsonl(SPEND)
    rev_rows = read_jsonl(REVENUE)
    key = stripe_key()
    note = ""
    if key:
        try:
            pull_sales(key)
            rev_rows = read_jsonl(REVENUE)
        except Exception as e:  # keep yesterday's numbers rather than dying
            note = f"(stripe unreachable: {e})"
    else:
        rev_rows, note = [], "no stripe key"

    spend, revenue, sales = euros(spend_rows), euros(rev_rows), len(rev_rows)
    lines = [
        f"Skills pack ledger — {d.isoformat()}",
        f"Spend to date: {spend:.2f} EUR of the 30 EUR cap ({len(spend_rows)} passes)",
        f"Revenue to date: {revenue:.2f} EUR, {sales} sales"
        + (f" {note}" if note else ""),
        f"Prices: launch {LAUNCH_PRICE} EUR, regular {REGULAR_PRICE} EUR, 30-day refund",
    ]
    launched = launch_date()
    if launched is None:
        lines.append(f"Kill line: not launched — no {POSTED.name} yet")
    else:
        deadline = launched + timedelta(days=KILL_DAYS)
        days_left = (deadline - d).days
        if sales < KILL_SALES and days_left <= 0:
            KILLED.write_text(
                f"KILLED {d.isoformat()}: launch {launched.isoformat()} +{KILL_DAYS}d, "
                f"{sales} sales (< {KILL_SALES})\n")
            lines.append("KILLED — kill line fired, this row stops work")
        elif sales >= KILL_SALES:
            lines.append(f"Kill line: cleared ({sales} sales by {deadline.isoformat()})")
        else:
            lines.append(f"Kill line: {days_left} days left (deadline {deadline.isoformat()}, "
                         f"needs {KILL_SALES} sales)")
    body = "\n".join(lines) + "\n"
    LEDGER_MD.write_text(body)
    return body


def selftest():
    tmp = Path(tempfile.mkdtemp(prefix="ledger-test-"))
    (tmp / "spend.jsonl").write_text(
        '{"date":"2026-09-06","row":"00-ledger","eur":0}\n'
        '{"date":"2026-09-07","row":"03-launch-posts","eur":1.5}\n')
    (tmp / "revenue.jsonl").write_text(
        '{"id":"ch_1","date":"2026-09-07T10:00:00+00:00","eur":19,"currency":"eur"}\n')
    launch = (date.today() - timedelta(days=89)).isoformat()
    (tmp / "launch").mkdir()
    (tmp / "launch" / "posted.jsonl").write_text(f'{{"date":"{launch}"}}\n')
    global DIR, SPEND, REVENUE, POSTED, LEDGER_MD, KILLED
    DIR = tmp
    SPEND = tmp / "spend.jsonl"
    REVENUE = tmp / "revenue.jsonl"
    POSTED = tmp / "launch" / "posted.jsonl"
    LEDGER_MD = tmp / "ledger.md"
    KILLED = tmp / "KILLED"
    body = build()
    assert "1.50 EUR of the 30 EUR cap" in body, body
    assert "19.00 EUR, 1 sales" in body, body
    assert "1 days left" in body or "0 days left" in body, body
    assert not (tmp / "KILLED").exists(), "kill line fired a day early"
    # one more day: deadline passed at 1 sale -> KILLED
    (tmp / "launch" / "posted.jsonl").write_text(
        '{"date":"' + (date.today() - timedelta(days=90)).isoformat() + '"}\n')
    body = build()
    assert "KILLED" in body, body
    assert (tmp / "KILLED").exists()
    # 3 sales clears it
    (tmp / "KILLED").unlink()
    (tmp / "revenue.jsonl").write_text(
        '{"id":"ch_1","date":"2026-09-07T10:00:00+00:00","eur":19,"currency":"eur"}\n'
        '{"id":"ch_2","date":"2026-09-08T10:00:00+00:00","eur":19,"currency":"eur"}\n'
        '{"id":"ch_3","date":"2026-09-08T11:00:00+00:00","eur":19,"currency":"eur"}\n')
    body = build()
    assert "cleared" in body, body
    print("selftest ok")


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        selftest()
    else:
        sys.stdout.write(build())
