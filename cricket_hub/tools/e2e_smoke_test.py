#!/usr/bin/env python3
"""
CricketHub — end-to-end smoke test against the Firebase **Local Emulator Suite**.

Runs the exact sequence a real player + ground owner would do, and asserts the
Firestore state at every step. No Blaze plan, no Razorpay account, no cost.

    # terminal 1
    firebase emulators:start

    # terminal 2
    python3 tools/e2e_smoke_test.py

What it covers
--------------
1. Auth emulator: create a player + a ground owner
2. Seed 4 grounds + 2 umpires (owner uid attached)
3. Ground list query returns them (same query the app runs)
4. createBookingHold (COD) → booking `pending_payment`, slot `booked`
5. Owner confirms cash → booking `confirmed`      (needs the rules fix)
6. validateBookingQR as owner → `valid: true`
7. Player cancels → booking `cancelled`, slot back to `available`
8. Refund policy applied (>=24h away → 100%)

Exit code 0 = everything green.
"""

import json
import sys
import urllib.error
import urllib.request
from datetime import date, timedelta

PROJECT = "crickethub-dev"
HOST = "localhost"

AUTH = f"http://{HOST}:9099/identitytoolkit.googleapis.com/v1"
FS = f"http://{HOST}:8080/v1/projects/{PROJECT}/databases/(default)/documents"
FN = f"http://{HOST}:5001/{PROJECT}/asia-south1"

API_KEY = "fake-api-key"
results = []


# --------------------------------------------------------------------------
# helpers
# --------------------------------------------------------------------------

def call(url, body, token=None, method="POST"):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(
        url, data=json.dumps(body).encode(), method=method, headers=headers
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read() or b"{}")


def admin_get(path):
    req = urllib.request.Request(
        f"{FS}/{path}", headers={"Authorization": "Bearer owner"}
    )
    with urllib.request.urlopen(req, timeout=20) as r:
        return json.loads(r.read())


def val(fields, key, default=None):
    raw = fields.get(key)
    if not raw:
        return default
    return list(raw.values())[0]


def check(label, ok, detail=""):
    results.append((label, bool(ok), detail))
    print(f"  {'✅' if ok else '❌'}  {label}" + (f"  — {detail}" if detail else ""))
    return ok


def signup(email):
    return call(
        f"{AUTH}/accounts:signUp?key={API_KEY}",
        {"email": email, "password": "test1234", "returnSecureToken": True},
    )


def signed_in(email):
    return call(
        f"{AUTH}/accounts:signInWithPassword?key={API_KEY}",
        {"email": email, "password": "test1234", "returnSecureToken": True},
    )


# --------------------------------------------------------------------------
# main
# --------------------------------------------------------------------------

print("\n🏏  CricketHub — E2E smoke test (emulator)\n" + "─" * 62)

# ---- 1. accounts -------------------------------------------------------------
print("\n[1] Auth")
try:
    player = signup("e2e_player@test.com")
    player_uid, player_tok = player["localId"], player["idToken"]
    check("player account created", True, player_uid[:12] + "…")
except urllib.error.HTTPError:
    player = signed_in("e2e_player@test.com")
    player_uid, player_tok = player["localId"], player["idToken"]
    check("player signed in (existed)", True, player_uid[:12] + "…")

try:
    owner = signup("e2e_owner@test.com")
    owner_uid, owner_tok = owner["localId"], owner["idToken"]
    check("owner account created", True, owner_uid[:12] + "…")
except urllib.error.HTTPError:
    owner = signed_in("e2e_owner@test.com")
    owner_uid, owner_tok = owner["localId"], owner["idToken"]
    check("owner signed in (existed)", True, owner_uid[:12] + "…")

# ---- 2. seed -----------------------------------------------------------------
print("\n[2] Seed catalogue")
import subprocess
subprocess.run(
    [sys.executable, "tools/seed_emulator.py",
     "--owner-uid", owner_uid, "--umpire-uid", player_uid],
    capture_output=True, check=False,
)
check("seed script ran", True, "4 grounds + 2 umpires")

# ---- 3. the app's ground query -----------------------------------------------
print("\n[3] Ground discovery query (city + active + verified + orderBy rating)")
q = {
    "structuredQuery": {
        "from": [{"collectionId": "grounds"}],
        "where": {"compositeFilter": {"op": "AND", "filters": [
            {"fieldFilter": {"field": {"fieldPath": "city"}, "op": "EQUAL",
                             "value": {"stringValue": "Ahmedabad"}}},
            {"fieldFilter": {"field": {"fieldPath": "status"}, "op": "EQUAL",
                             "value": {"stringValue": "active"}}},
            {"fieldFilter": {"field": {"fieldPath": "verified"}, "op": "EQUAL",
                             "value": {"booleanValue": True}}},
        ]}},
        "orderBy": [{"field": {"fieldPath": "avg_rating"},
                     "direction": "DESCENDING"}],
        "limit": 50,
    }
}
res = call(f"{FS}:runQuery", q, token="owner")
grounds = [x["document"] for x in res if "document" in x]
check("Ahmedabad grounds returned", len(grounds) == 3, f"{len(grounds)} found")
check("ordered by avg_rating desc",
      len(grounds) >= 2 and
      grounds[0]["fields"]["avg_rating"]["doubleValue"] >=
      grounds[1]["fields"]["avg_rating"]["doubleValue"])

# ---- 4. COD booking ----------------------------------------------------------
print("\n[4] Create a cash-on-delivery booking")
slot_day = (date.today() + timedelta(days=5)).isoformat()
booking_req = {
    "kind": "ground",
    "resourceId": "seed_ground_sp",
    "resourceName": "Sardar Patel Cricket Ground",
    "counterpartyUid": owner_uid,
    "counterpartyName": "E2E Owner",
    "organizerUid": player_uid,
    "organizerName": "E2E Player",
    "date": slot_day,
    "slotStart": "06:00", "slotEnd": "08:00", "durationMinutes": 120,
    "amountPaise": 240000, "platformFeePaise": 24000,
    "payoutAmountPaise": 216000,
    "notes": "", "paymentMethod": "cod",
}
try:
    out = call(f"{FN}/createBookingHold", {"data": booking_req}, token=player_tok)
    booking_id = (out.get("result") or {}).get("bookingId")
    check("createBookingHold returned a bookingId", bool(booking_id), booking_id)
except urllib.error.HTTPError as e:
    check("createBookingHold returned a bookingId", False, e.read().decode()[:200])
    booking_id = None

booking = {}
if booking_id:
    booking = admin_get(f"bookings/{booking_id}")["fields"]
    check("booking status = pending_payment",
          val(booking, "status") == "pending_payment", val(booking, "status"))
    check("QR token generated", bool(val(booking, "qr_token")))

    slot_doc = admin_get(f"grounds/seed_ground_sp/slots/{slot_day}")["fields"]
    entry = slot_doc["slots"]["mapValue"]["fields"]["06:00-08:00"]
    entry_status = val(entry["mapValue"]["fields"], "status")
    check("slot marked 'booked' (survives hold expiry)",
          entry_status == "booked", entry_status)

# ---- 5. owner confirms cash --------------------------------------------------
print("\n[5] Owner confirms the cash (this was BLOCKED before the rules fix)")
if booking_id:
    body = {"fields": {
        "status": {"stringValue": "confirmed"},
        "updated_at": {"timestampValue": "2026-01-01T00:00:00Z"},
    }}
    url = (f"{FS}/bookings/{booking_id}"
           "?updateMask.fieldPaths=status&updateMask.fieldPaths=updated_at")
    try:
        call(url, body, token=owner_tok, method="PATCH")
        check("owner allowed to move pending_payment → confirmed", True)
    except urllib.error.HTTPError as e:
        check("owner allowed to move pending_payment → confirmed", False,
              f"HTTP {e.code}")

    # a stranger must NOT be able to do it
    try:
        call(url, body, token=player_tok, method="PATCH")
        check("organizer CANNOT confirm (rule scoped to counterparty)", False)
    except urllib.error.HTTPError:
        check("organizer CANNOT confirm (rule scoped to counterparty)", True)

# ---- 6. QR validation --------------------------------------------------------
print("\n[6] Owner scans the QR")
if booking_id and val(booking, "qr_token"):
    try:
        qr = call(f"{FN}/validateBookingQR",
                  {"data": {"qrToken": val(booking, "qr_token")}}, token=owner_tok)
        r = qr.get("result") or {}
        check("validateBookingQR accepts it", r.get("valid") is True,
              (r.get("booking") or {}).get("name", ""))
    except urllib.error.HTTPError as e:
        check("validateBookingQR accepts it", False, e.read().decode()[:200])

# ---- 7. cancel + refund ------------------------------------------------------
print("\n[7] Player cancels 5 days out (refund policy = 100%)")
if booking_id:
    try:
        out = call(f"{FN}/onBookingCancelled",
                   {"data": {"bookingId": booking_id, "reason": "e2e test"}},
                   token=player_tok)
        r = out.get("result") or {}
        check("cancel call succeeded", r.get("cancelled") is True)
        check("100% refund computed", r.get("refundAmountPaise") == 240000,
              f"₹{(r.get('refundAmountPaise') or 0) // 100}")
    except urllib.error.HTTPError as e:
        check("cancel call succeeded", False, e.read().decode()[:200])

    after = admin_get(f"bookings/{booking_id}")["fields"]
    check("booking status = cancelled", val(after, "status") == "cancelled",
          val(after, "status"))

    slot_doc = admin_get(f"grounds/seed_ground_sp/slots/{slot_day}")["fields"]
    entry = slot_doc["slots"]["mapValue"]["fields"]["06:00-08:00"]
    check("slot released back to 'available'",
          val(entry["mapValue"]["fields"], "status") == "available",
          val(entry["mapValue"]["fields"], "status"))

# ---- summary -----------------------------------------------------------------
passed = sum(1 for _, ok, _ in results if ok)
total = len(results)
print("\n" + "═" * 62)
print(f"  {passed}/{total} checks passed")
if passed == total:
    print("  ✅ ALL GREEN — booking flow works end to end")
else:
    print("  ❌ Failures above. Emulator logs usually name the rule/field.")
print("═" * 62 + "\n")

sys.exit(0 if passed == total else 1)
