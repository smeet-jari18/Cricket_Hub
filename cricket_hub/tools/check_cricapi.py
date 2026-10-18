#!/usr/bin/env python3
"""Live smoke check for the Phase-4 CricAPI integration.

The Flutter tests use mocked HTTP, so they prove our *parsing* but never touch
the real API. This script does the opposite: one real request, human-readable
output. Run it once before a release to confirm the key and the response shape
have not drifted.

    python3 tools/check_cricapi.py                 # uses $CRICAPI_KEY
    python3 tools/check_cricapi.py --key abc123
    python3 tools/check_cricapi.py --raw           # dump the JSON
    python3 tools/check_cricapi.py --demo          # CricAPI's public demo key:
                                                   # shows the rejection path
                                                   # without an account
    python3 tools/check_cricapi.py --json          # machine-readable result

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


def fetch(key: str, base: str = BASE) -> tuple[int, dict]:
    query = urllib.parse.urlencode({"apikey": key, "offset": "0"})
    request = urllib.request.Request(
        f"{base}?{query}",
        headers={"User-Agent": "CricketHub-Phase4-Check/1.0"},
    )
    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            return response.status, json.loads(response.read().decode())
    except urllib.error.HTTPError as exc:
        return exc.code, {}
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        # A dead network is not a dead key — say so instead of dumping a stack.
        return -1, {"reason": str(getattr(exc, "reason", exc))}


def main() -> int:
    parser = argparse.ArgumentParser(description="CricAPI live smoke check")
    parser.add_argument("--key", default=os.environ.get("CRICAPI_KEY", ""))
    parser.add_argument("--raw", action="store_true", help="print the raw JSON")
    parser.add_argument("--demo", action="store_true",
                        help="use CricAPI's public demo key (always rejected) to "
                             "see what a bad key looks like")
    parser.add_argument("--json", action="store_true", help="machine-readable output")
    parser.add_argument("--base", default=BASE, help=argparse.SUPPRESS)
    args = parser.parse_args()

    key = "demo" if args.demo else args.key.strip()
    if not key:
        print("No key. Pass --key or export CRICAPI_KEY.")
        print("Free key: https://cricapi.com  (100 hits/day)")
        return 2

    status, payload = fetch(key, args.base)
    if args.raw:
        print(json.dumps(payload, indent=2)[:4000])

    if status == -1:
        reason = payload.get("reason", "unknown")
        print(f"FAIL  could not reach CricAPI: {reason}")
        print("      Network/DNS problem, not a key problem. Retry, or check that")
        print("      this machine can reach https://api.cricapi.com")
        return 4

    if payload.get("status") == "failure":
        reason = payload.get("reason", "unknown")
        lowered = str(reason).lower()
        if "hit" in lowered and ("limit" in lowered or "exceed" in lowered):
            print(f"FAIL  quota exhausted: {reason}")
            print("      Resets at midnight UTC. The app shows 'Daily CricAPI limit")
            print("      reached' and offers demo data until then.")
        elif "invalid" in lowered or "key" in lowered:
            print(f"FAIL  key rejected: {reason}")
            print("      Copy it again from https://cricapi.com (no spaces). A new")
            print("      key can take a few minutes to activate.")
        else:
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

    if args.json:
        print(json.dumps({
            "ok": True,
            "matches": len(matches),
            "live": len(live),
            "upcoming": len(upcoming),
            "completed": len(done),
            "hitsToday": info.get("hitsToday"),
            "hitsLimitToday": info.get("hitsLimitToday"),
        }))

    print("")
    print("Next: run the app with the same key —")
    print("      flutter run --dart-define=CRICAPI_KEY=<your key>")
    print("      International tab should show live cards with no 'Demo data' banner.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
