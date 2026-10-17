#!/usr/bin/env python3
"""
Seed the Firebase **Firestore Emulator** with demo grounds + umpires so the
CricketHub app has something to show during device testing.

Why this exists
---------------
`GroundService.groundsByCityStream()` only returns docs where

    city        == <selected city>
    status      == 'active'
    verified    == true
    avg_rating   (orderBy field — a doc missing it is dropped from results)

So a fresh emulator shows an empty ground list and it *looks* broken.

Usage
-----
    # 1. start the suite (separate terminal)
    firebase emulators:start --only auth,firestore,functions

    # 2. seed
    python3 tools/seed_emulator.py

    # owner panel bhi test karna ho to apna uid do:
    python3 tools/seed_emulator.py --owner-uid <YOUR_FIREBASE_UID>
    python3 tools/seed_emulator.py --umpire-uid <SAME_OR_OTHER_UID>

No external deps — uses urllib only.
Emulator REST calls send `Authorization: Bearer owner`, which the Firestore
emulator treats as full admin access (bypasses security rules for seeding).
"""

import argparse
import json
import sys
import urllib.error
import urllib.request

# --------------------------------------------------------------------------
# Firestore REST value helpers
# --------------------------------------------------------------------------

def s(v):
    return {"stringValue": v}


def i(v):
    return {"integerValue": str(int(v))}


def d(v):
    return {"doubleValue": float(v)}


def b(v):
    return {"booleanValue": bool(v)}


def arr(*values):
    return {"arrayValue": {"values": list(values)}}


def TS(v="2026-01-01T00:00:00Z"):
    return {"timestampValue": v}


# --------------------------------------------------------------------------
# Demo data
# --------------------------------------------------------------------------

def make_ground(name, address, city, pitch, wd, we, full, open_t, close_t,
                slot_min, seller_uid, rating, reviews, bookings):
    return {
        "name": s(name),
        "owner_uid": s(seller_uid),
        "city": s(city),
        "address": s(address),
        "lat": d(23.0225),
        "lng": d(72.5714),
        "pitch_type": s(pitch),
        "amenities": arr(s("Floodlights"), s("Parking"), s("Washroom"),
                         s("Drinking water"), s("Pavilion")),
        "photos": arr(),
        "cover_photo_url": s(""),
        "price_weekday_hourly": i(wd),
        "price_weekend_hourly": i(we),
        "price_full_day": i(full),
        "open_time": s(open_t),
        "close_time": s(close_t),
        "slot_duration_minutes": i(slot_min),
        "status": s("active"),
        "verified": b(True),
        "avg_rating": d(rating),
        "review_count": i(reviews),
        "booking_count": i(bookings),
        "ground_stats": {"mapValue": {"fields": {}}},
        "created_at": TS(),
        "updated_at": TS(),
    }


def make_umpire(uid, name, phone, city, exp, day_rate, hourly, bio,
                rating, reviews, matches, status="active", verified=True):
    return {
        "user_uid": s(uid),
        "display_name": s(name),
        "phone_number": s(phone),
        "city": s(city),
        "experience_years": i(exp),
        "certifications": arr(),
        "day_rate": i(day_rate),
        "hourly_rate": i(hourly),
        "bio": s(bio),
        "photo_url": s(""),
        "status": s(status),
        "verified": b(verified),
        "avg_rating": d(rating),
        "review_count": i(reviews),
        "matches_officiated": i(matches),
        "created_at": TS(),
        "updated_at": TS(),
    }


# --------------------------------------------------------------------------
# REST plumbing
# --------------------------------------------------------------------------

BASE = "http://{host}:{port}/v1/projects/{project}/databases/(default)/documents"


def post_doc(host, port, project, collection, doc_id, fields):
    """Create/replace one document. Returns True on success."""
    url = BASE.format(host=host, port=port, project=project)
    url = f"{url}/{collection}?documentId={doc_id}"
    body = json.dumps({"fields": fields}).encode()
    req = urllib.request.Request(
        url,
        data=body,
        method="POST",
        headers={
            "Content-Type": "application/json",
            "Authorization": "Bearer owner",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            resp.read()
        return True
    except urllib.error.HTTPError as e:
        detail = e.read().decode()[:300]
        print(f"   ✗ {collection}/{doc_id} → HTTP {e.code}: {detail}")
        return False
    except urllib.error.URLError as e:
        print(f"   ✗ {collection}/{doc_id} → cannot reach emulator: {e.reason}")
        return False


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--host", default="localhost")
    ap.add_argument("--port", type=int, default=8080)
    ap.add_argument("--project", default="crickethub-dev")
    ap.add_argument("--owner-uid", default="SEED_OWNER_UID",
                    help="grounds ka owner_uid — apna uid do to owner panel test ho")
    ap.add_argument("--umpire-uid", default="SEED_UMPIRE_UID",
                    help="umpires/{uid} doc id — apna uid do to umpire dashboard test ho")
    args = ap.parse_args()

    o = args.owner_uid
    u = args.umpire_uid

    grounds = {
        "seed_ground_sp": make_ground(
            "Sardar Patel Cricket Ground", "Navrangpura, Ahmedabad", "Ahmedabad",
            "turf", 1200, 1500, 9000, "06:00", "22:00", 120, o, 4.6, 18, 42),
        "seed_ground_nm": make_ground(
            "Nana Mava Sports Arena", "Nana Mava Road, Rajkot bypass, Ahmedabad",
            "Ahmedabad", "matting", 800, 1000, 6000, "07:00", "21:00", 60, o,
            4.2, 9, 21),
        "seed_ground_rf": make_ground(
            "Riverfront Box Cricket", "Sabarmati Riverfront, Ahmedabad",
            "Ahmedabad", "concrete", 600, 750, 4200, "18:00", "23:00", 60, o,
            3.9, 5, 13),
        "seed_ground_mum": make_ground(
            "Dadar Parsi Colony Ground", "Dadar, Mumbai", "Mumbai", "turf",
            1500, 1800, 11000, "06:00", "22:00", 120, o, 4.8, 31, 77),
    }

    umpires = {
        u: make_umpire(
            u, "Ravi Sharma", "+919800000001", "Ahmedabad", 8, 250000, 35000,
            "State-level umpire. 200+ club matches. Calm under pressure.",
            4.7, 12, 214),
        "seed_umpire_2": make_umpire(
            "seed_umpire_2", "Imran Qureshi", "+919800000002", "Ahmedabad", 5,
            180000, 25000, "Weekend specialist for box cricket and T20 leagues.",
            4.3, 7, 96),
    }

    print(f"\n🌱 Seeding {args.project} emulator at {args.host}:{args.port}\n")

    ok = 0
    total = 0

    print("  grounds/")
    for doc_id, fields in grounds.items():
        total += 1
        if post_doc(args.host, args.port, args.project, "grounds",
                    doc_id, fields):
            print(f"   ✓ {doc_id:<22} {fields['name']['stringValue']}")
            ok += 1

    print("\n  umpires/")
    for doc_id, fields in umpires.items():
        total += 1
        if post_doc(args.host, args.port, args.project, "umpires",
                    doc_id, fields):
            print(f"   ✓ {doc_id:<22} {fields['display_name']['stringValue']}")
            ok += 1

    print(f"\n{'─' * 62}")
    print(f"  {ok}/{total} documents written")

    if o == "SEED_OWNER_UID":
        print("\n  ⚠️  owner_uid = 'SEED_OWNER_UID'")
        print("     Ground list + calendar + booking kaam karenge.")
        print("     Owner panel khaali rahega — apna uid do:")
        print("       python3 tools/seed_emulator.py --owner-uid <YOUR_UID>")

    print("\n  Ab app chalao:")
    print("    flutter run --dart-define=USE_EMULATOR=true")
    print("\n  Emulator UI:  http://localhost:4000")
    print()
    return 0 if ok == total else 1


if __name__ == "__main__":
    sys.exit(main())
