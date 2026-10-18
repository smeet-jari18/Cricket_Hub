#!/usr/bin/env python3
"""Concurrency test: 50 organizers try to book the SAME ground slot at the
same moment. Exactly one must win; the other 49 must get ABORTED.

    firebase emulators:start            # terminal 1
    python3 tools/stress_test_booking.py   # terminal 2

Why this matters: `createBookingHold` reserves the slot inside a Firestore
transaction. If that transaction were not doing its job (e.g. a read outside
the transaction, or the slot map updated with a blind `set`), two players could
both "win" the same 06:00–07:00 slot and one of them would turn up to a ground
that is already occupied.

Each of the 50 callers is a distinct auth user, so the function's idempotency
short-circuit (same organizer + same slot returns the existing hold) can never
mask a race.
"""

from __future__ import annotations

import argparse
import sys
import threading
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone

import emulator_common as ec

PROJECT = ec.PROJECT_ID
GROUND_ID = "ground_stress"


def iso(days: int = 0) -> str:
    return (datetime.now(timezone.utc) + timedelta(days=days)).strftime("%Y-%m-%d")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("-n", "--requests", type=int, default=50)
    args = ap.parse_args()
    n = args.requests

    c = ec.Checks()
    print("=" * 70)
    print(f" CricketHub — slot race test: {n} concurrent bookings, one slot")
    print("=" * 70)

    ec.fs_clear()
    ec.auth_delete_all()

    owner_uid, _ = ec.create_auth_user("owner.stress@crickethub.test")
    ec.fs_set_admin(f"grounds/{GROUND_ID}", {
        "name": "Stress Test Ground",
        "owner_uid": owner_uid,
        "city": "Ahmedabad",
        "address": "Stress Street",
        "lat": 23.0,
        "lng": 72.5,
        "pitch_type": "turf",
        "amenities": [],
        "photos": [],
        "cover_photo_url": "",
        "price_weekday_hourly": 1000,
        "price_weekend_hourly": 1000,
        "price_full_day": 8000,
        "open_time": "06:00",
        "close_time": "22:00",
        "slot_duration_minutes": 60,
        "status": "active",
        "verified": True,
        "avg_rating": 0.0,
        "review_count": 0,
        "booking_count": 0,
        "ground_stats": {},
    })
    print(f"  ✓ seeded {GROUND_ID}; creating {n} organizer accounts…")

    players = []
    for i in range(n):
        uid, tok = ec.create_auth_user(f"racer{i:02d}.stress@crickethub.test")
        players.append((uid, tok))
    print("  ✓ accounts ready\n")

    date = iso(5)
    slot_start, slot_end = "09:00", "10:00"

    barrier = threading.Barrier(n)
    results: list[tuple[int, bool, str]] = []
    lock = threading.Lock()

    def attempt(idx: int) -> None:
        uid, tok = players[idx]
        try:
            barrier.wait(timeout=60)  # fire them all at the same instant
        except threading.BrokenBarrierError:
            pass
        try:
            ok, res = ec.call("createBookingHold", {
                "kind": "ground",
                "resourceId": GROUND_ID,
                "resourceName": "Stress Test Ground",
                "counterpartyUid": owner_uid,
                "counterpartyName": "Stress Owner",
                "organizerUid": uid,
                "organizerName": f"Racer {idx}",
                "date": date,
                "slotStart": slot_start,
                "slotEnd": slot_end,
                "durationMinutes": 60,
                "amountPaise": 100000,
                "platformFeePaise": 5000,
                "payoutAmountPaise": 95000,
                "paymentMethod": "cod",
            }, token=tok)
        except Exception as exc:  # noqa: BLE001 - a timeout is a data point
            ok, res = False, f"CLIENT_ERROR:{type(exc).__name__}"
        with lock:
            results.append((idx, ok, "OK" if ok else str(res)))

    print(f"  Firing {n} requests at {date} {slot_start}-{slot_end}…")
    with ThreadPoolExecutor(max_workers=n) as pool:
        list(pool.map(attempt, range(n)))

    winners = [r for r in results if r[1]]
    aborted = [r for r in results if (not r[1]) and r[2] == "ABORTED"]
    others = [r for r in results if (not r[1]) and r[2] != "ABORTED"]

    print(f"\n  winners : {len(winners)}")
    print(f"  aborted : {len(aborted)}")
    print(f"  other   : {len(others)}")
    if others:
        from collections import Counter
        for code, count in Counter(r[2] for r in others).items():
            print(f"      {code}: {count}")

    c.section("results")
    c.check(f"exactly 1 of {n} concurrent bookings won", len(winners) == 1,
            f"winners={len(winners)}")
    c.check(f"all {n - 1} losers got ABORTED",
            len(aborted) == n - 1,
            f"aborted={len(aborted)} other={len(others)}")
    c.check("no unexpected error codes", not others,
            ", ".join(sorted({r[2] for r in others})))

    # The winner's booking must be alive and the slot committed.
    if winners:
        _, slot_doc = ec.fs_get(f"grounds/{GROUND_ID}/slots/{date}", token="owner")
        entry = (ec.from_doc(slot_doc.get("fields", {}))
                 .get("slots", {}).get(f"{slot_start}-{slot_end}", {}) or {})
        c.check("slot ends up `booked` with exactly one booking_id",
                entry.get("status") == "booked" and bool(entry.get("booking_id")),
                f"entry={entry}")
        # Only one booking document may exist for this slot.
        _, q = ec._request(
            "POST",
            f"http://{ec.FIRESTORE_HOST}/v1/projects/{PROJECT}"
            "/databases/(default)/documents:runQuery",
            {"structuredQuery": {
                "from": [{"collectionId": "bookings"}],
                "where": {"compositeFilter": {"op": "AND", "filters": [
                    {"fieldFilter": {"field": {"fieldPath": "resource_id"},
                                     "op": "EQUAL", "value": {"stringValue": GROUND_ID}}},
                    {"fieldFilter": {"field": {"fieldPath": "date"},
                                     "op": "EQUAL", "value": {"stringValue": date}}},
                ]}},
            }},
            token="owner",
        )
        docs = [r["document"] for r in (q if isinstance(q, list) else []) if "document" in r]
        c.check("exactly one booking document exists for the slot", len(docs) == 1,
                f"found {len(docs)}")

    return c.finish()


if __name__ == "__main__":
    sys.exit(main())
