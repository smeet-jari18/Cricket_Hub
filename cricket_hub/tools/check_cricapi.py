#!/usr/bin/env python3
"""Live smoke check for the Phase-4 CricAPI integration.

The Flutter tests use mocked HTTP, so they prove our *parsing* but never touch
the real API. This script does the opposite: one real request, human-readable
output. Run it once before a release to confirm the key and the response shape
have not drifted.

    python3 tools/check_cricapi.py                 # uses $CRICAPI_KEY
    python3 tools/check_cricapi.py --key abc123
    python3 tools/check_cricapi.py --raw           # dump the JSON

Exit codes:
    0  key works, response looks right
    2  no key given
    3  key rejected / quota gone
    4  network or unexpected payload
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

BASE = "https://api.cricapi.com/v1/currentMatches"


def fetch(key: str) -> tuple[int, dict]:
    query = urllib.parse.urlencode({"apikey": key, "offset": "0"})
    request = urllib.request.Request(
        f"{BASE}?{query}",
        headers={"User-Agent": "CricketHub-Phase4-Check/1.0"},
    )
    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            return response.status, json.loads(response.read().decode())
    except urllib.error.HTTPError as exc:
        return exc.code, {}


def main() -> int:
    parser = argparse.ArgumentParser(description="CricAPI live smoke check")
    parser.add_argument("--key", default=os.environ.get("CRICAPI_KEY", ""))
    parser.add_argument("--raw", action="store_true", help="print the raw JSON")
    args = parser.parse_args()

    key = args.key.strip()
    if not key:
        print("No key. Pass --key or export CRICAPI_KEY.")
        print("Free key: https://cricapi.com  (100 hits/day)")
        return 2

    status, payload = fetch(key)
    if args.raw:
        print(json.dumps(payload, indent=2)[:4000])

    if payload.get("status") == "failure":
        reason = payload.get("reason", "unknown")
        print(f"FAIL  CricAPI said: {reason}")
        return 3

    if status != 200:
        print(f"FAIL  HTTP {status}")
        return 4

    matches = payload.get("data")
    if not isinstance(matches, list):
        print("FAIL  response has no 'data' list — shape changed")
        return 4

    live = [m for m in matches if m.get("matchStarted") and not m.get("matchEnded")]
    upcoming = [m for m in matches if not m.get("matchStarted")]
    done = [m for m in matches if m.get("matchEnded")]

    print(f"OK    {len(matches)} matches "
          f"({len(live)} live, {len(upcoming)} upcoming, {len(done)} completed)")

    for match in matches[:5]:
        teams = " v ".join(match.get("teams") or [])
        print(f"  - {match.get('name', '?')}")
        print(f"      {teams} | {match.get('matchType', '?')} | "
              f"{match.get('status', '')[:70]}")

    # The fields the Flutter model actually reads. A missing one here means the
    # screen would render blanks — worth seeing before a release, not after.
    required = ("id", "name", "teams", "matchStarted", "matchEnded")
    if matches:
        missing = [field for field in required if field not in matches[0]]
        if missing:
            print(f"WARN  first match is missing: {', '.join(missing)}")
            return 4

    info = payload.get("info") or {}
    if info:
        print(f"      quota: {info.get('hitsToday')}/{info.get('hitsLimitToday')} today")

    return 0


if __name__ == "__main__":
    sys.exit(main())
