# Phase-3 Status — Razorpay ko chhodkar

**Branch:** `phase-3_update` · **Project:** `crickethub-dev` · **Region:** `asia-south1`
**Verified on:** Flutter 3.47.7 (Dart 3.13.5) · JDK 21.0.12 · firebase-tools 15.34.0 · Node 20.20
**Last run:** 2026-10-18

---

## 1. Verification table

| # | Check | Target | Result | Kaise verify hua |
|---|---|---|---|---|
| P0 | `flutter analyze` | 0 issues | ✅ **No issues found!** | poore `lib/` + `test/` + `integration_test/` pe |
| P0 | `flutter test` | 58/58 | ✅ **107/107** | 58 existing + 49 naye (+12 storage) |
| P1 | `functions npm test` | 27/27 | ✅ **35/35** | `node --test`, 5 suites (+8 notification) |
| P1 | rules tests | 32/32 | ✅ **47/47** | real `firestore.rules` + emulator (+6 review, +9 admin) |
| P2 | `e2e_smoke_test.py` | 16/16 | ✅ **24/24** | 3+ baar chalaya (idempotent) |
| P2 | `stress_test_booking.py` | PASS, 1 winner | ⚠️ **PASS @ n=10**, n=50 ❌ | 1 winner / 9 ABORTED / 0 other. 50 liye 4 GB+ RAM chahiye |
| P3 | Photo upload | Storage ho to done | ✅ **code + rules verified** · ⚠️ device pe upload ❌ | `storage.rules` 19/19 emulator pe; asli upload device + Blaze maangta hai |
| P4 | Integration test | device pe | ⏸️ **Pending** | device nahi; scaffold compile-clean |
| — | Umpire booking flow | compile + emulator | ✅ | E2E 13–15 |
| — | Edit screens | compile + update | ✅ | E2E 16 + validator unit tests |
| — | Razorpay | chhua nahi | ✅ | payment code jaisa tha waisa |

**Clean-room proof:** zip fresh extract → `pub get` → `analyze` (0 issues) → `test` (95/95) — pass.

---

## 2. Phase-3 completeness audit (docs vs code)

Project ke apne 7 Phase-3 docs (PRD, AppFlow, Implementation Plan, Backend Schema,
Security, TRD, UI/UX) ke against har sprint item check kiya:

| Sprint | Doc requirement | Status |
|---|---|---|
| 6 | `ground_model/service/list/detail/filter_sheet` | ✅ sab maujood |
| 6 | Discovery me **search + filter + sort** | ✅ **is round fix hua** — search pehle dead tha |
| 7 | Calendar, slot picker, checkout, `createBookingHold`, `expireStaleHolds` | ✅ |
| 8 | Razorpay: order / verify / webhook | ✅ (out of scope, untouched) |
| 8 | QR display, `onBookingConfirmed` CF | ⚠️ QR ✅ · **`onBookingConfirmed` nahi hai** (dekho §5) |
| 9 | Owner dashboard, create ground, calendar, earnings, QR scanner | ✅ |
| 9 | image resize + storage rules | ✅ **ban gaya** — picker 1600px/quality 80 pe downscale karta hai, `storage.rules` + 19 emulator checks |
| 10 | Umpire model/service/list/detail/dashboard/availability/onboarding | ✅ |
| 10 | **Umpire accept/decline** (AppFlow Flow 9) | ✅ **is round add hua** — pehle sirf accept tha |
| 11 | `booking_detail`, `leave_review`, `rating_stars` | ✅ (review flow **is round harden hua**) |
| 11 | `onBookingCancelled`, `aggregateGroundRating`, `weeklyPayoutDigest` | ✅ |
| 12 | 50 concurrent booking stress | ⚠️ n=10 pass, n=50 RAM se ruka |
| 12 | Refund edge cases (24h/12h/0h) | ✅ `booking_model_test.dart` |
| 12 | TestFlight/Closed Testing | ⏸️ device + console chahiye |
| Security | Threat: **"Self-booking + self-review"** | ✅ **is round fix hua** — review ab `booking_id` + `completed` maangta hai |
| Security | Umpire phone PII rules | ✅ (rules-test [1b]) |
| Security | `admin`/`ground_owner` custom claims | ⚠️ claims nahi; rules `/admins/{uid}` doc use karte hain (documented deviation) |
| AppFlow 8 | Admin verification step (ground `verified=true`) | ✅ **ban gaya** — admin queue screen |
| AppFlow 7 | Owner ko "New booking" FCM | ✅ code + trigger verified; push delivery device pe pending |

---

## 3. Is round me kya fix hua (4 defects)

### 3.1 Review integrity — documented threat model enforce nahi tha ⚠️ behaviour change
`docs/CricketHub_Security_Phase3.md` likhta hai: *"Self-booking + self-review — Reviews require
`booking_id`; Cloud Function verifies `booking.status === 'completed'`"*.
Reality: review client se **seedha** likha jata tha, **bina `booking_id`** ke. Matlab koi bhi naya
account kisi bhi ground ko 1-star kar sakta tha (ya khud ko 5-star).

Fix:
- `firestore.rules`: naye helper `isCompletedGroundBookingFor()` / `isCompletedUmpireBookingFor()`.
  Review tabhi accept hota hai jab booking exist kare, `organizer_uid == auth.uid` ho,
  `status == 'completed'` ho, aur `resource_id`/`counterparty_uid` match kare.
- `review_service.dart`: `bookingId` required + client-side readable error.
- `leave_review_screen.dart`: booking ke bina submit block.
- `booking_detail_screen.dart`: umpire booking ke liye "Rate this umpire"; `bookingId` pass hota hai.
- `umpire_detail_screen.dart`: "Leave a review" button hata diya (wahan booking context hi nahi tha).

**Iska matlab:** purane clients jo bina `booking_id` review likhte the, unhe ab
`permission-denied` milega. App code update ho chuka hai. **Revert karna ho** to
`firestore.rules` me `isCompleted*BookingFor(...)` condition hata do — baaki kuch nahi.

### 3.2 Umpire request decline missing tha (App Flow 9)
Flow kehta hai "Accept **or Decline**"; rules `status in ['confirmed','cancelled']` allow karte hain,
par app me sirf accept tha. Add: `declineUmpireBooking()` + request card me "Decline"
(confirm dialog ke saath). E2E check 19.

### 3.3 Ground search box dead control tha
`onChanged` me sirf comment tha — typing se kuch nahi hota tha. Ab `lib/core/geo.dart` ka
`groundMatchesQuery()` name/city/address/pitch pe client-side filter karta hai, clear button ke saath.

### 3.4 "Distance" sort sabke liye 0 return karta tha
`return (a, b) => 0;` — yaani menu me option tha, kaam nahi karta tha. Ab haversine
(`distanceKm()`) se **city centre** se doori se sort hota hai, aur label honest hai:
"Distance (city centre)" — location permission Phase 3.5 ka kaam hai.

---

## 4. Naye files (cumulative)

**Screens:** `umpire_booking_screen.dart`, `umpire_booking_requests_screen.dart`,
`umpire_edit_screen.dart`, `owner_edit_ground_screen.dart`
**Core:** `lib/core/geo.dart` (naya — haversine + search)
**Storage (naya):** `storage.rules`, `lib/services/storage_service.dart`,
`lib/services/photo_picker.dart`
**Services:** `booking_service.dart` (+`createUmpireBooking`, `confirmUmpireCodBooking`, `declineUmpireBooking`)
**Modified:** `review_service.dart`, `leave_review_screen.dart`, `booking_detail_screen.dart`,
`umpire_detail_screen.dart`, `umpire_dashboard.dart`, `owner_dashboard.dart`,
`ground_list_screen.dart`, `main.dart`, `firestore.rules`, `pubspec.yaml`
**Tests:** `umpire_booking_price_test.dart` (12), `edit_forms_validation_test.dart` (14),
`ground_search_test.dart` (11), `storage_service_test.dart` (12),
`integration_test/app_flow_test.dart`,
`rules-test/rules.test.js` (+6 review checks), `rules-test/storage.test.js` (19 checks)
**Tools:** `emulator_common.py`, `seed_emulator.py`, `e2e_smoke_test.py` (19 checks),
`stress_test_booking.py`, `README.md`, `functions/.secret.local`, `functions/.env.example`

---

## 5. Pending — aur kyun

| Cheez | Status | Reason |
|---|---|---|
| ~~Admin verification UI~~ | ✅ **DONE** | `admin_verification_screen.dart` + `admin_service.dart` + `/admins` read rule. E2E 20–24 |
| **Push delivery (asli FCM)** | ⚠️ partial | Code + trigger chal rahe hain (`user_<uid>` topic), par asli notification bhejne ke liye real Firebase creds + device chahiye. Sandbox me FCM send fail hota hai (caught) |
| **Photo upload — device pe asli upload** | ⚠️ partial | Code + rules dono verify ho gaye (Dart 12/12, rules 19/19 emulator pe). Par sandbox me na device hai na real Firebase project. `flutterfire configure` + Ek device pe ek photo upload hi asli proof dega. Runtime pe Blaze plan chahiye |
| **`stress -n 50`** | ⏸️ | 2 GB sandbox; Functions emulator per-call ~80 MB Node runtime |
| **Integration test** | ⏸️ | device/emulator nahi |
| **Distance sort = user location** | ⏸️ | `geolocator` + permission (Phase 3.5); abhi city centre |
| **Custom claims (`admin`, `ground_owner`)** | ⏸️ | Rules `/admins/{uid}` doc-based hain — kaam karta hai, doc se alag |
| **Razorpay** | ⏸️ | Aapka explicit decision |

---

## 6. Kaise chalayein

```bash
export PATH=/opt/flutter/bin:$PATH
cd cricket_hub

flutter pub get
flutter analyze && flutter test                 # 0 issues · 107/107

cd functions && npm install && npm test         # 35/35
cd ../rules-test && npm install --legacy-peer-deps && npm test   # 47/47

# Terminal 1
firebase emulators:start
# Terminal 2
python3 tools/seed_emulator.py
python3 tools/e2e_smoke_test.py                 # 24/24
python3 tools/stress_test_booking.py -n 10      # PASS (1 winner)
```

**Secrets:** `functions/.secret.local` (dev placeholders, `.gitignore`d).
Production: `firebase functions:secrets:set QR_JWT_SECRET`.

### 6.1 Storage rules test — do jaal jinme main khud phansa

`firebase emulators:start --only auth,firestore,storage --project demo-crickethub`
ke chalte hue: `cd rules-test && node storage.test.js` → **19/19**.

`@firebase/rules-unit-testing@4` me Storage support **hai hi nahi**, isliye ye
suite emulator ki REST API se baat karta hai. Do baatein jo pehli baar me galat
thi — dobara mat karna:

1. **`multipart/form-data` bhejna `/v0/b/{bucket}/o?name=...` par.**
   Emulator poora envelope hi object maan leta hai, to
   `request.resource.contentType` ban jaata hai
   `"multipart/form-data; boundary=..."` — har `image/*` rule fail, aur dikhta
   hai jaise rules galat hain. Sahi tarika:
   `Content-Type: multipart/related` + header `X-Goog-Upload-Protocol: multipart`.
2. **`/upload/storage/v1/b/{bucket}/o?uploadType=multipart` use karna.**
   Ye endpoint emulator me GCS ka *admin* API hai — ye `storage.rules`
   **bypass** karta hai, anonymous upload bhi 200 deta hai. Test green dikhta
   hai aur kuch bhi prove nahi karta. Rules sirf `/v0/` par lagti hain.

Boundary ko bhi pin kiya hai: 5MB exactly **allowed**, 5MB+1 **denied** —
sirf "denied" check karna jhooth bol sakta hai (agar rule `size <= 1` ho to bhi
wo pass ho jaata). Delete **204** return karta hai, 200 nahi.

Suite sach me rules pe react karti hai — mutation test: owner-check hatane par
19 me se 3 checks red ho jaate hain, wapas lagane par 19/19.

---

## 7. E2E 19 checks

| # | Check | Kis cheez ko prove karta hai |
|---|---|---|
| 1–2 | anon deny / organizer allow | rules auth boundary |
| 3–4 | COD booking create → `pending_payment` | booking lifecycle |
| 5 | slot = `booked` (not `held`) | **B2** |
| 6–8 | stranger deny / owner allow / stranger confirm deny | per-doc privacy |
| 9 | owner confirm → `confirmed` | **B1** |
| 10 | owner close → `completed` | **B3** |
| 11 | review on completed booking → allow | review path |
| 12 | same slot again → `ABORTED` | slot lock |
| 13 | umpire COD booking | umpire marketplace |
| 14 | umpire `cod_confirmed_at` → 403 | rule scope (isliye alag method) |
| 15 | umpire `status`+`updated_at` → `confirmed` | umpire cash confirm |
| 16 | umpire edit fields → 200 | edit screen field-set |
| 17 | review **without** `booking_id` → 403 | **self-review fix** |
| 18 | review on someone else's booking → 403 | **self-review fix** |
| 19 | umpire decline → `cancelled` | **App Flow 9** |
| 20 | admin own `/admins` read → 200 | admin roster |
| 21 | non-admin admin-doc read → 403 | roster privacy |
| 22 | pending ground invisible to players | verification gate |
| 23 | owner cannot self-verify → 403 | **admin panel ka core** |
| 24 | admin approve → `active` + `verified` | **ground goes live** |

---

## 8. Agla step

Ab code-side blockers khatam hain. Bacha hua kaam sab external hai:
`flutterfire configure` (real apiKey) → device pe push + integration test → 4 GB+ machine pe
`stress -n 50` → Blaze le kar photo upload → phir Razorpay.
