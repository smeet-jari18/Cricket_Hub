#!/usr/bin/env python3
"""Seeds the Firebase Emulator Suite with a bookable ground + an active umpire.

    firebase emulators:start              # terminal 1
    python3 tools/seed_emulator.py        # terminal 2

Optional — reuse UIDs you already created (e.g. from the Emulator UI at
http://localhost:4000):

    python3 tools/seed_emulator.py --owner-uid OWNER_UID --umpire-uid UMPIRE_UID

If a UID is not supplied the script creates (or reuses) an Auth-emulator user
and prints the UID + idToken, so you can log in with that account in the app.

Seeding writes with ``Authorization: Bearer owner`` (the emulator's admin
bypass). Nothing here is a security test — e2e_smoke_test.py is what checks the
rules.
"""

from __future__ import annotations

import argparse
import sys
from datetime import datetime, timedelta, timezone

import emulator_common as ec

GROUND_ID = "ground_demo_ahmedabad"
OWNER_EMAIL = "owner@crickethub.test"
UMPIRE_EMAIL = "umpire@crickethub.test"
PLAYER_EMAIL = "player@crickethub.test"


def iso(days: int = 0) -> str:
    return (datetime.now(timezone.utc) + timedelta(days=days)).strftime("%Y-%m-%d")


def seed_ground(owner_uid: str, owner_name: str) -> None:
    ec.fs_set_admin(f"grounds/{GROUND_ID}", {
        "name": "Sardar Patel Cricket Ground",
        "owner_uid": owner_uid,
        "city": "Ahmedabad",
        "address": "Nr. SG Highway, Ahmedabad, Gujarat 380054",
        "lat": 23.0225,
        "lng": 72.5714,
        "pitch_type": "turf",
        "amenities": ["floodlights", "parking", "change_room", "drinking_water"],
        "photos": [],
        "cover_photo_url": "",
        "price_weekday_hourly": 1200,
        "price_weekend_hourly": 1500,
        "price_full_day": 9000,
        "open_time": "06:00",
        "close_time": "22:00",
        "slot_duration_minutes": 60,
        "status": "active",
        "verified": True,
        "avg_rating": 4.6,
        "review_count": 12,
        "booking_count": 34,
        # `ground_stats` is read by the owner earnings/analytics screens; an
        # empty map keeps every reader happy.
        "ground_stats": {},
    })
    print(f"  ✓ grounds/{GROUND_ID}  (owner: {owner_name})")


def seed_umpire(umpire_uid: str, name: str) -> None:
    ec.fs_set_admin(f"umpires/{umpire_uid}", {
        "user_uid": umpire_uid,
        "display_name": name,
        "phone_number": "+919000000002",
        "city": "Ahmedabad",
        "experience_years": 8,
        "certifications": [
            {"name": "GCA Level 1", "document_url": "", "verified": True},
        ],
        "day_rate": 4000,
        "hourly_rate": 500,
        "bio": "Local league umpire, 8 years, 120+ matches.",
        "photo_url": "",
        "status": "active",
        "verified": True,
        "avg_rating": 4.7,
        "review_count": 9,
        "matches_officiated": 120,
    })
    print(f"  ✓ umpires/{umpire_uid}  ({name})")


def seed_user(uid: str, name: str, phone: str, role: str) -> None:
    ec.fs_set_admin(f"users/{uid}", {
        "phone_number": phone,
        "display_name": name,
        "player_name_key": name.lower(),
        "avatar_url": "",
        "role": role,
        "batting_style": "right",
        "bowling_style": "right",
    })


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--owner-uid", help="existing UID to use as the ground owner")
    ap.add_argument("--umpire-uid", help="existing UID to use as the umpire")
    ap.add_argument("--player-uid", help="existing UID to use as the organizer")
    args = ap.parse_args()

    print("Seeding crickethub-dev emulator...\n")

    created = {}

    def resolve(flag_value, email, label):
        if flag_value:
            # Existing UID -> try to mint a token for it; the user was made
            # through the Emulator UI with email/password, otherwise the app
            # can still sign in with the account they already have.
            print(f"  · {label}: using supplied UID {flag_value}")
            return flag_value
        uid, token = ec.create_auth_user(email)
        created[label] = (uid, token)
        print(f"  · {label}: new auth user {email} -> {uid}")
        return uid

    owner_uid = resolve(args.owner_uid, OWNER_EMAIL, "owner")
    umpire_uid = resolve(args.umpire_uid, UMPIRE_EMAIL, "umpire")
    player_uid = resolve(args.player_uid, PLAYER_EMAIL, "player")

    print("\nWriting documents:")
    seed_user(owner_uid, "Sardar Patel Sports Club", "+919000000001", "owner")
    seed_user(umpire_uid, "Ramesh Bhai", "+919000000002", "umpire")
    seed_user(player_uid, "Test Player", "+919000000003", "player")
    seed_ground(owner_uid, "Sardar Patel Sports Club")
    seed_umpire(umpire_uid, "Ramesh Bhai")

    # A couple of bookable dates so the calendar is not empty.
    for offset in (0, 1, 2):
        ec.fs_set_admin(f"grounds/{GROUND_ID}/slots/{iso(offset)}", {
            "date": iso(offset),
            "blocked": False,
            "slots": {},
        })

    print("\n" + "=" * 64)
    print("  UIDs — app me login karne ke liye")
    print("=" * 64)
    print(f"  owner  : {owner_uid}")
    print(f"  umpire : {umpire_uid}")
    print(f"  player : {player_uid}")
    print(f"  ground : {GROUND_ID}  (active + verified, ₹1200/hr)")
    for label, (uid, token) in created.items():
        print(f"\n  {label} idToken (curl ke liye):")
        print(f"    {token[:40]}…")
    print("\n  Flutter app:  flutter run --dart-define=USE_EMULATOR=true")
    print("  Emulator UI:  http://localhost:4000")
    print("=" * 64)
    return 0


if __name__ == "__main__":
    sys.exit(main())
