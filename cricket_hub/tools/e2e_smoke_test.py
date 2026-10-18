#!/usr/bin/env python3
"""End-to-end smoke test for the Phase-3 booking lifecycle, against the
Firebase Emulator Suite. 16 checks.

    firebase emulators:start        # terminal 1
    python3 tools/e2e_smoke_test.py # terminal 2

Everything here uses real end-user ID tokens, so Firestore security rules are
actually enforced (the emulator only bypasses them for ``Bearer owner``, which
is used for seeding alone).

What it proves:
  B1  a ground owner can confirm a COD booking        (checks  8–9)
  B2  a COD slot is committed as `booked`, not `held` (check   5)
  B3  a booking can reach `completed`                 (check  10)
  +   umpire COD booking → umpire confirms            (checks 13–15)
  +   the exact rule scope: writing cod_confirmed_at as the umpire is refused
      (check 14) — that is why BookingService.confirmUmpireCodBooking exists
  +   edit-screen field sets are inside the rules' allow-lists (check 16)

The script is self-contained: it creates its own auth users and seeds its own
ground/umpire, so it never depends on what is already in the emulator.
``seed_emulator.py`` is the separate tool for getting demo data into the app.
"""

from __future__ import annotations

import sys
from datetime import datetime, timedelta, timezone

import emulator_common as ec

PROJECT = ec.PROJECT_ID
GROUND_ID = "ground_e2e"
UMPIRE_NAME = "E2E Umpire"


def iso(days: int = 0) -> str:
    return (datetime.now(timezone.utc) + timedelta(days=days)).strftime("%Y-%m-%d")


def main() -> int:
    c = ec.Checks()

    print("=" * 70)
    print(" CricketHub — Phase 3 E2E smoke test (emulator)")
    print(f" project={PROJECT}  auth={ec.AUTH_HOST}  firestore={ec.FIRESTORE_HOST}"
          f"  functions={ec.FUNCTIONS_HOST}")
    print("=" * 70)

    # ---------------------------------------------------------------- setup
    c.section("setup")

    # Fresh state every run: a stale "slot already booked" from a previous run
    # would make the race assertions meaningless.
    ec.fs_clear()
    ec.auth_delete_all()

    organizer_uid, organizer_tok = ec.create_auth_user("organizer.e2e@crickethub.test")
    owner_uid, owner_tok = ec.create_auth_user("owner.e2e@crickethub.test")
    umpire_uid, umpire_tok = ec.create_auth_user("umpire.e2e@crickethub.test")
    stranger_uid, stranger_tok = ec.create_auth_user("stranger.e2e@crickethub.test")
    anon_tok = None
    print(f"  organizer={organizer_uid[:12]}…  owner={owner_uid[:12]}…  "
          f"umpire={umpire_uid[:12]}…  stranger={stranger_uid[:12]}…")

    ec.fs_set_admin(f"grounds/{GROUND_ID}", {
        "name": "E2E Cricket Ground",
        "owner_uid": owner_uid,
        "city": "Ahmedabad",
        "address": "E2E Street 1",
        "lat": 23.0,
        "lng": 72.5,
        "pitch_type": "turf",
        "amenities": ["floodlights"],
        "photos": [],
        "cover_photo_url": "",
        "price_weekday_hourly": 1000,
        "price_weekend_hourly": 1200,
        "price_full_day": 8000,
        "open_time": "06:00",
        "close_time": "22:00",
        "slot_duration_minutes": 60,
        "status": "active",
        "verified": True,
        "avg_rating": 4.5,
        "review_count": 3,
        "booking_count": 10,
        "ground_stats": {},
    })
    ec.fs_set_admin(f"umpires/{umpire_uid}", {
        "user_uid": umpire_uid,
        "display_name": UMPIRE_NAME,
        "phone_number": "+919000000009",
        "city": "Ahmedabad",
        "experience_years": 5,
        "certifications": [],
        "day_rate": 4000,
        "hourly_rate": 500,
        "bio": "",
        "photo_url": "",
        "status": "active",
        "verified": True,
        "avg_rating": 4.0,
        "review_count": 1,
        "matches_officiated": 20,
    })
    print("  ✓ ground + umpire seeded (admin bypass)")

    date = iso(3)
    slot_start, slot_end = "06:00", "07:00"
    slot_key = f"{slot_start}-{slot_end}"

    # ------------------------------------------------------- 1-2 read access
    c.section("grounds: read access")

    status, _ = ec.fs_get(f"grounds/{GROUND_ID}", token=anon_tok)
    c.check("1. anon CANNOT read a ground", status == 403, f"got HTTP {status}")

    status, body = ec.fs_get(f"grounds/{GROUND_ID}", token=organizer_tok)
    c.check("2. organizer CAN read an active+verified ground", status == 200,
            f"got HTTP {status}")

    # ------------------------------------------- 3-5 COD ground booking (B2)
    c.section("COD ground booking")

    ok, res = ec.call("createBookingHold", {
        "kind": "ground",
        "resourceId": GROUND_ID,
        "resourceName": "E2E Cricket Ground",
        "counterpartyUid": owner_uid,
        "counterpartyName": "E2E Owner",
        "organizerUid": organizer_uid,
        "organizerName": "E2E Organizer",
        "date": date,
        "slotStart": slot_start,
        "slotEnd": slot_end,
        "durationMinutes": 60,
        "amountPaise": 100000,
        "platformFeePaise": 5000,
        "payoutAmountPaise": 95000,
        "notes": "e2e",
        "paymentMethod": "cod",
    }, token=organizer_tok)
    booking_id = res.get("bookingId") if ok else None
    c.check("3. organizer creates a COD ground booking", ok and bool(booking_id),
            f"error={res}")

    booking_path = f"bookings/{booking_id}"
    status, doc = ec.fs_get(booking_path, token=organizer_tok)
    fields = ec.from_doc(doc.get("fields", {})) if status == 200 else {}
    c.check("4. booking lands as pending_payment / cod",
            status == 200
            and fields.get("status") == "pending_payment"
            and fields.get("payment_method") == "cod",
            f"status={fields.get('status')} method={fields.get('payment_method')}")

    # Admin read on purpose: the slot map is part of the seeded document
    # tree and an anonymous GET would be denied by the rules.
    _, slot_doc = ec.fs_get(f"grounds/{GROUND_ID}/slots/{date}", token="owner")
    entry = (ec.from_doc(slot_doc.get("fields", {}))
             .get("slots", {}).get(slot_key, {}) or {})
    c.check("5. B2 — COD slot is committed as `booked`, not `held`",
            entry.get("status") == "booked",
            f"slot status={entry.get('status')!r}")

    # --------------------------------------------- 6-8 visibility + refusals
    c.section("booking visibility")

    status, _ = ec.fs_get(booking_path, token=stranger_tok)
    c.check("6. stranger CANNOT read someone else's booking", status == 403,
            f"got HTTP {status}")

    status, _ = ec.fs_get(booking_path, token=owner_tok)
    c.check("7. ground owner CAN read the booking", status == 200,
            f"got HTTP {status}")

    status, _ = ec.fs_patch(
        booking_path,
        {"status": "confirmed", "updated_at": "2026-01-01T00:00:00Z"},
        token=stranger_tok,
    )
    c.check("8. stranger CANNOT confirm the cash", status == 403,
            f"got HTTP {status}")

    # ------------------------------------------- 9-10 owner lifecycle (B1/B3)
    c.section("owner confirms cash, then closes the booking")

    status, _ = ec.fs_patch(
        booking_path,
        {
            "status": "confirmed",
            "cod_confirmed_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-01-01T00:00:00Z",
        },
        token=owner_tok,
    )
    ok_confirm = status == 200
    status2, doc2 = ec.fs_get(booking_path, token=owner_tok)
    f2 = ec.from_doc(doc2.get("fields", {})) if status2 == 200 else {}
    c.check("9. B1 — owner confirm moves pending_payment → confirmed",
            ok_confirm and f2.get("status") == "confirmed"
            and f2.get("cod_confirmed_at") is not None
            and f2.get("cod_confirmed_at") != "",
            f"patch={status} status={f2.get('status')}")

    status, _ = ec.fs_patch(
        booking_path,
        {"status": "completed", "updated_at": "2026-01-01T00:00:00Z"},
        token=owner_tok,
    )
    status2, doc2 = ec.fs_get(booking_path, token=owner_tok)
    f3 = ec.from_doc(doc2.get("fields", {})) if status2 == 200 else {}
    c.check("10. B3 — owner closes the booking → completed",
            status == 200 and f3.get("status") == "completed",
            f"patch={status} status={f3.get('status')}")

    # ------------------------------------------------------------- 11 review
    c.section("review after completion")

    status, _ = ec.fs_create("ground_reviews/review_e2e_1", {
        "ground_id": GROUND_ID,
        "owner_uid": owner_uid,
        "booking_id": booking_id,
        "reviewer_uid": organizer_uid,
        "reviewer_name": "E2E Organizer",
        "rating": 5,
        "text": "Great pitch.",
    }, token=organizer_tok)
    c.check("11. organizer CAN review the completed booking", status == 200,
            f"got HTTP {status}")

    c.section("review integrity (self-review / drive-by review)")

    status, _ = ec.fs_create("ground_reviews/review_nobooking", {
        "ground_id": GROUND_ID,
        "reviewer_uid": stranger_uid,
        "rating": 1,
        "text": "Never played here.",
    }, token=stranger_tok)
    c.check("17. review WITHOUT booking_id is rejected", status == 403,
            f"got HTTP {status}")

    status, _ = ec.fs_create("ground_reviews/review_someone_else", {
        "ground_id": GROUND_ID,
        "booking_id": booking_id,
        "reviewer_uid": stranger_uid,
        "rating": 1,
        "text": "Not my booking.",
    }, token=stranger_tok)
    c.check("18. review on someone else's booking is rejected", status == 403,
            f"got HTTP {status}")

    # -------------------------------------------------------- 12 slot is gone
    c.section("slot locking")

    ok2, res2 = ec.call("createBookingHold", {
        "kind": "ground",
        "resourceId": GROUND_ID,
        "resourceName": "E2E Cricket Ground",
        "counterpartyUid": owner_uid,
        "organizerUid": stranger_uid,
        "organizerName": "Stranger",
        "date": date,
        "slotStart": slot_start,
        "slotEnd": slot_end,
        "durationMinutes": 60,
        "amountPaise": 100000,
        "platformFeePaise": 5000,
        "paymentMethod": "cod",
    }, token=stranger_tok)
    c.check("12. booking the same slot again is ABORTED", (not ok2) and res2 == "ABORTED",
            f"ok={ok2} error={res2}")

    # ---------------------------------------------- 13-15 umpire COD booking
    c.section("umpire COD booking")

    ok3, res3 = ec.call("createBookingHold", {
        "kind": "umpire",
        "resourceId": umpire_uid,
        "resourceName": UMPIRE_NAME,
        "counterpartyUid": umpire_uid,
        "counterpartyName": UMPIRE_NAME,
        "organizerUid": organizer_uid,
        "organizerName": "E2E Organizer",
        "date": date,
        "slotStart": "12:00",
        "slotEnd": "15:00",
        "durationMinutes": 180,
        "amountPaise": 150000,
        "platformFeePaise": 7500,
        "payoutAmountPaise": 142500,
        "paymentMethod": "cod",
    }, token=organizer_tok)
    umpire_booking_id = res3.get("bookingId") if ok3 else None
    umpire_path = f"bookings/{umpire_booking_id}"
    ok_kind = False
    if umpire_booking_id:
        _, d = ec.fs_get(umpire_path, token=organizer_tok)
        fd = ec.from_doc(d.get("fields", {}))
        ok_kind = fd.get("kind") == "umpire" and fd.get("status") == "pending_payment"
    c.check("13. organizer books an umpire (COD, pending_payment)",
            ok3 and ok_kind, f"error={res3}")

    # Deliberately wrong write: the ground-owner field set (status +
    # cod_confirmed_at + updated_at). MUST be refused for an umpire booking.
    status, _ = ec.fs_patch(
        umpire_path,
        {
            "status": "confirmed",
            "cod_confirmed_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-01-01T00:00:00Z",
        },
        token=umpire_tok,
    )
    c.check("14. umpire CANNOT write cod_confirmed_at (rule scope)",
            status == 403, f"got HTTP {status}")

    status, _ = ec.fs_patch(
        umpire_path,
        {"status": "confirmed", "updated_at": "2026-01-01T00:00:00Z"},
        token=umpire_tok,
    )
    _, d2 = ec.fs_get(umpire_path, token=umpire_tok)
    fu = ec.from_doc(d2.get("fields", {}))
    c.check("15. umpire confirms with status+updated_at → confirmed",
            status == 200 and fu.get("status") == "confirmed",
            f"patch={status} status={fu.get('status')}")

    # App Flow 9: the umpire can also DECLINE an incoming request.
    ok4, res4 = ec.call("createBookingHold", {
        "kind": "umpire",
        "resourceId": umpire_uid,
        "resourceName": UMPIRE_NAME,
        "counterpartyUid": umpire_uid,
        "counterpartyName": UMPIRE_NAME,
        "organizerUid": organizer_uid,
        "organizerName": "E2E Organizer",
        "date": date,
        "slotStart": "17:00",
        "slotEnd": "20:00",
        "durationMinutes": 180,
        "amountPaise": 150000,
        "platformFeePaise": 7500,
        "payoutAmountPaise": 142500,
        "paymentMethod": "cod",
    }, token=organizer_tok)
    decline_path = f"bookings/{res4.get('bookingId')}" if ok4 else None
    status = 0
    declined = ""
    if decline_path:
        status, _ = ec.fs_patch(
            decline_path,
            {"status": "cancelled", "updated_at": "2026-01-01T00:00:00Z"},
            token=umpire_tok,
        )
        _, d4 = ec.fs_get(decline_path, token=umpire_tok)
        declined = ec.from_doc(d4.get("fields", {})).get("status", "")
    c.check("19. umpire CAN decline a request → cancelled",
            ok4 and status == 200 and declined == "cancelled",
            f"call={ok4} patch={status} status={declined!r}")

    # ------------------------------------------- 20-22 admin verification
    c.section("admin verification queue")

    admin_uid, admin_tok = ec.create_auth_user("admin.e2e@crickethub.test")
    ec.fs_set_admin(f"admins/{admin_uid}", {"granted_at": "2026-01-01T00:00:00Z"})

    status, _ = ec.fs_get(f"admins/{admin_uid}", token=admin_tok)
    c.check("20. admin CAN read own /admins entry", status == 200,
            f"got HTTP {status}")

    status, _ = ec.fs_get(f"admins/{admin_uid}", token=organizer_tok)
    c.check("21. non-admin CANNOT read the admin entry", status == 403,
            f"got HTTP {status}")

    # A second ground, this time submitted for verification by its owner.
    pending_id = "ground_e2e_pending"
    ec.fs_set_admin(f"grounds/{pending_id}", {
        "name": "Pending E2E Ground",
        "owner_uid": owner_uid,
        "city": "Ahmedabad",
        "address": "Pending Street 2",
        "lat": 23.0,
        "lng": 72.5,
        "pitch_type": "turf",
        "amenities": [],
        "photos": [],
        "cover_photo_url": "",
        "price_weekday_hourly": 900,
        "price_weekend_hourly": 1100,
        "price_full_day": 0,
        "open_time": "06:00",
        "close_time": "22:00",
        "slot_duration_minutes": 60,
        "status": "pending_verification",
        "verified": False,
        "avg_rating": 0.0,
        "review_count": 0,
        "booking_count": 0,
        "ground_stats": {},
    })

    status, _ = ec.fs_get(f"grounds/{pending_id}", token=organizer_tok)
    c.check("22. pending ground is invisible to players", status == 403,
            f"got HTTP {status}")

    status, _ = ec.fs_patch(
        f"grounds/{pending_id}",
        {"verified": True, "status": "active",
         "updated_at": "2026-01-01T00:00:00Z"},
        token=owner_tok,
    )
    c.check("23. owner CANNOT self-verify their ground", status == 403,
            f"got HTTP {status}")

    status, _ = ec.fs_patch(
        f"grounds/{pending_id}",
        {"verified": True, "status": "active",
         "updated_at": "2026-01-01T00:00:00Z"},
        token=admin_tok,
    )
    read_status, d5 = ec.fs_get(f"grounds/{pending_id}", token=organizer_tok)
    approved = ec.from_doc(d5.get("fields", {})) if read_status == 200 else {}
    c.check("24. admin approves → ground goes live for players",
            status == 200 and approved.get("status") == "active"
            and approved.get("verified") is True,
            f"patch={status} status={approved.get('status')!r}")

    # ------------------------------------------------- 16 umpire edit screen
    c.section("edit screens")

    status, _ = ec.fs_patch(
        f"umpires/{umpire_uid}",
        {
            "display_name": "E2E Umpire Renamed",
            "bio": "Updated via umpire edit screen.",
            "experience_years": 6,
            "hourly_rate": 600,
            "day_rate": 4500,
            "updated_at": "2026-01-01T00:00:00Z",
        },
        token=umpire_tok,
    )
    _, d3 = ec.fs_get(f"umpires/{umpire_uid}", token=umpire_tok)
    fe = ec.from_doc(d3.get("fields", {}))
    c.check("16. umpire CAN update the exact fields the edit screen sends",
            status == 200 and fe.get("display_name") == "E2E Umpire Renamed"
            and fe.get("hourly_rate") == 600,
            f"patch={status} name={fe.get('display_name')!r}")

    return c.finish()


if __name__ == "__main__":
    sys.exit(main())
