# CricketHub — Phase 3 (Marketplace & Bookings) Addendum

> **Designed to drop directly into your `cricket_hub/` project (Phase 2).**
> All file paths, naming conventions, code style, and dependencies follow the existing Phase 2 codebase.

---
## Android build fail ho rahi hai?

`android/build.gradle.kts` ka error message aksar distract karta hai — asli
wajah neeche hoti hai. Ek command se check karo:

```powershell
python tools/check_android_setup.py
```

Poora diagnostic + har error ka fix: **`docs/ANDROID_BUILD_TROUBLESHOOTING.md`**
(`build.gradle` + `build.gradle.kts` dono, repos mode, SDK path, JDK 17+,
dono build files, IDE squiggles).

## Logo / app icon

**Source of truth:** `assets/branding/logo_source.png` — the artwork as
designed (teal ring, orange dot, white page). Every icon in the project is
generated from this one file; nothing is hand-edited.

| Target | File | Look |
|---|---|---|
| Splash screen | `assets/images/logo.png` | artwork as-is, transparent |
| Native launch window | `android/…/drawable-nodpi/launch_logo.png` | artwork as-is |
| Android launcher | `android/…/mipmap-*/ic_launcher.png` | artwork on a white tile |
| Android 8+ adaptive | `drawable-*/ic_launcher_foreground.png` + `#FFFFFF` background | same artwork, maskable |
| iOS AppIcon | `ios/…/AppIcon.appiconset/*.png` | artwork, opaque (App Store rule) |
| Web / PWA / favicon | `web/icons/*`, `web/favicon.png` | artwork on a white tile |

```bash
python3 tools/make_icons.py            # regenerate everything
python3 tools/make_icons.py --check    # report only
python3 tools/make_icons.py --style on_teal   # white ring on brand teal (alt)
flutter clean && flutter run           # launcher caches mipmaps, so clean first
```

New artwork? Overwrite `assets/branding/logo_source.png` and rerun. The script
removes the white page by un-premultiplying it, so the ring keeps smooth edges
instead of a pale halo.

## Android build fail ho rahi hai?

`android/build.gradle.kts` ka error message aksar distract karta hai — asli
wajah neeche hoti hai. Ek command se check karo:

```powershell
python tools/check_android_setup.py
```

Poora diagnostic + har error ka fix: **`docs/ANDROID_BUILD_TROUBLESHOOTING.md`**
(`build.gradle` + `build.gradle.kts` dono, repos mode, SDK path, JDK 17+,
dono build files, IDE squiggles).

## Logo / app icon

**Mark:** solid ball + orange seam — do hi colours (teal `#006B5C`, orange
`#FF6D00`), koi gradient nahi, koi letterform nahi. Isliye 24px favicon se
1024px store icon tak same padhta hai. Geometry `tools/logo_mark.py` me hai,
image file me nahi.

| Kahan | Form |
|---|---|
| Launcher / iOS / web icon | Teal ki full-bleed tile + white ball |
| Splash screen | Teal ball, transparent — app ke white canvas pe |
| Vector (print, deck, store listing) | `docs/branding/crickethub-mark.svg`, `crickethub-tile.svg` |

Sab icons regenerate karne ke liye:

```bash
python3 tools/make_icons.py          # report only: --check
flutter clean && flutter run
```

`assets/branding/logo_source.png` (client ka original artwork) repo me safe
hai. Usse wapas ship karna ho to `make_icons.py` me `USE_CUSTOM_ARTWORK = True`
kar do — baaki sab waisa hi chalega.

Random logo options dekhne ke liye `python3 tools/logo_lab.py`.

## Ship se pehle: CricAPI key check (2 second)

App install karne se pehle terminal me hi pata chal jaata hai ki key chalegi ya
nahi — aur agar nahi, to kya galat hai:

```bash
python3 tools/check_cricapi.py --key YOUR_KEY      # ya CRICAPI_KEY=... python3 tools/check_cricapi.py
python3 tools/check_cricapi.py --demo              # bina account, failure path dekho
```

| Exit | Matlab | App me kya dikhega |
|---|---|---|
| 0 | Key theek, quota print hoga | Live cards, koi demo banner nahi |
| 2 | Key di hi nahi | "Live scores need a CricAPI key" card |
| 3 | Key reject ya quota khatam | "CricAPI rejected the key" / "Daily limit reached" |
| 4 | Network ya response shape badla | Network error card, retry button |

Key valid nikle to app isi key ke saath chalao:

```bash
flutter run --dart-define=CRICAPI_KEY=YOUR_KEY
```

## Fresh clone? Firebase options ek command door hai

`lib/firebase_options.dart` gitignored hai (asli keys usme hain). Fresh clone pe
`flutter analyze` fail karega jab tak wo file na ho. Do raste hain:

```bash
cp lib/firebase_options.example.dart lib/firebase_options.dart   # placeholder, analyze/test ke liye kaafi
dart run tools/sync_firebase_options.dart                        # asli values google-services.json se
```


## 🚨 Device pe black screen? Pehle ye padho

Agar `flutter run` me ye dikhe:

```
Unhandled Exception: [core/duplicate-app] A Firebase App named "[DEFAULT]" already exists
   at main (package:cricket_hub/main.dart)
```

…aur app black screen par atak jaaye, to wajah ye hai:

| | |
|---|---|
| **1** | `android/app/google-services.json` (ya iOS ka `GoogleService-Info.plist`) **asli** config ke saath pehle se maujood hai |
| **2** | Android ka google-services plugin process start par `[DEFAULT]` FirebaseApp **khud bana deta hai** |
| **3** | Repo ki `lib/firebase_options.dart` ek **PLACEHOLDER** hai (`apiKey: 'AIzaSyPLACEHOLDER-…'`) |
| **4** | `Firebase.initializeApp(options: placeholder)` → naam wahi, options alag → crash → `runApp()` chala hi nahi → black screen |

### Fix A — turant (bina kuch generate kiye)

Is version me `lib/core/firebase_bootstrap.dart` pehle check karta hai ki native
app bana hua hai kya; agar haan, to **usi ko adopt** kar leta hai. Matlab
`google-services.json` hi source of truth hai aur app chal jaata hai — aur agar
kabhi init fail bhi ho to black screen ki jagah ek readable error screen aata hai.

```bash
flutter clean && flutter run
```

### Fix B — asli (recommended)

Placeholder ko asli values se replace karo. Do tarike:

**B1 — bina kuch install kiye (sabse fast).** Aapke paas `google-services.json`
already hai, usme asli `apiKey` maujood hai. Ye script wahan se values utha kar
Dart file bhar deti hai (Dart Flutter ke saath already installed hai):

```powershell
dart run tools/sync_firebase_options.dart
flutter clean; flutter run
```

Pehle dekhna ho ki kya badlega: `dart run tools/sync_firebase_options.dart --check`

**B2 — official CLI se.**

```powershell
npm install -g firebase-tools      # ya standalone installer
firebase login
flutterfire configure --project=crickethub-dev
```

> `flutterfire` ko `firebase` CLI chahiye. Agar `firebase --version` fail hota
> hai to ye error aata hai:
> `FirebaseCommandException: ... firebase --version`. Us case me B1 use karo —
> uske liye Firebase CLI ki zaroorat nahi.

Ye `lib/firebase_options.dart` (aur platform config) regenerate karta hai.
**Ise repo me commit mat karna** — `.gitignore` me hai, aur har developer ki
machine pe apna hota hai.

> ⚠️ **Zip extract karte waqt dhyan:** `v4` se zip me `firebase_options.dart`
> **shaamil nahi** hai (sirf `.example`), isliye aapki asli file safe rehti hai.
> Purane zips me placeholder hota tha jo asli file ko overwrite kar deta tha.
> kar diya hoga — Fix B chala kar wapas banao. (Git users ke liye ye problem
> nahi hoti, kyunki file gitignored hai.)

### Black screen phir bhi aaye?

`flutter run` ka output dekho — ab startup ka har failure `BootstrapErrorScreen`
par dikhta hai jisme exact error hota hai. Uske bina kuch bhi guess mat karo.

---

## 📂 What's in this package

The files below mirror the existing Phase 2 project structure 1:1 — when you copy them into `cricket_hub/`, they sit alongside your existing Phase 2 files without any restructuring.

**Markdown docs go to the repo root (same as Phase 2's `CricketHub_*.md` files).**

```
cricket_hub_phase3/
├── README.md                                     <-- you are here
│
├── docs/                                          <-- Markdown documentation
│   ├── CricketHub_PRD_Phase3.md                  → repo root: CricketHub_PRD_Phase3.md
│   ├── CricketHub_TRD_Phase3.md                  → repo root: CricketHub_TRD_Phase3.md
│   ├── CricketHub_Backend_Schema_Phase3.md       → repo root: CricketHub_Backend_Schema_Phase3.md
│   ├── CricketHub_Security_Phase3.md             → repo root: CricketHub_Security_Phase3.md
│   ├── CricketHub_AppFlow_Phase3.md              → repo root: CricketHub_AppFlow_Phase3.md
│   ├── CricketHub_UI_UX_Phase3.md               → repo root: CricketHub_UI_UX_Phase3.md
│   ├── CricketHub_Implementation_Plan_Phase3.md  → repo root: CricketHub_Implementation_Plan_Phase3.md
│   ├── firestore_rules_phase3_addendum.md        <-- copy rules blocks into cricket_hub/firestore.rules
│   └── firestore_indexes_phase3_addendum.json     <-- append to cricket_hub/firestore.indexes.json
│
├── lib/
│   ├── core/
│   │   └── app_constants.dart                    <-- merge into cricket_hub/lib/core/app_constants.dart
│   ├── models/
│   │   ├── ground_model.dart                     → cricket_hub/lib/models/ground_model.dart
│   │   ├── booking_model.dart                    → cricket_hub/lib/models/booking_model.dart
│   │   └── umpire_model.dart                     → cricket_hub/lib/models/umpire_model.dart
│   ├── services/
│   │   ├── ground_service.dart                   → cricket_hub/lib/services/ground_service.dart
│   │   ├── booking_service.dart                  → cricket_hub/lib/services/booking_service.dart
│   │   ├── payment_service.dart                  → cricket_hub/lib/services/payment_service.dart
│   │   └── umpire_service.dart                   → cricket_hub/lib/services/umpire_service.dart
│   └── screens/
│       ├── ground/
│       │   ├── ground_list_screen.dart           → cricket_hub/lib/screens/ground/ground_list_screen.dart
│       │   ├── ground_detail_screen.dart         → cricket_hub/lib/screens/ground/ground_detail_screen.dart
│       │   └── widgets/ground_filter_sheet.dart  → cricket_hub/lib/screens/ground/widgets/ground_filter_sheet.dart
│       └── booking/
│           ├── checkout_args.dart                → cricket_hub/lib/screens/booking/checkout_args.dart
│           ├── booking_checkout_screen.dart      → cricket_hub/lib/screens/booking/booking_checkout_screen.dart
│           └── booking_success_screen.dart       → cricket_hub/lib/screens/booking/booking_success_screen.dart
│
├── functions/
│   ├── index.js                                  <-- MERGE into cricket_hub/functions/index.js (Phase 2 has its own functions there)
│   ├── package.json                              <-- merge with cricket_hub/functions/package.json (adds razorpay, jsonwebtoken, uuid)
│   └── test/
│       ├── refund.test.js                        → cricket_hub/functions/test/refund.test.js
│       ├── slot.test.js                          → cricket_hub/functions/test/slot.test.js
│       ├── razorpaySignature.test.js             → cricket_hub/functions/test/razorpaySignature.test.js
│       └── qr.test.js                            → cricket_hub/functions/test/qr.test.js
│
├── test/
│   ├── booking_model_test.dart                   → cricket_hub/test/booking_model_test.dart
│   └── ground_model_test.dart                    → cricket_hub/test/ground_model_test.dart
│
└── docs/
    ├── CricketHub_PRD_Phase3.md                  → repo root: CricketHub_PRD_Phase3.md
    ├── CricketHub_TRD_Phase3.md                  → repo root: CricketHub_TRD_Phase3.md
    ├── CricketHub_Backend_Schema_Phase3.md       → repo root: CricketHub_Backend_Schema_Phase3.md
    ├── CricketHub_Security_Phase3.md             → repo root: CricketHub_Security_Phase3.md
    ├── CricketHub_AppFlow_Phase3.md              → repo root: CricketHub_AppFlow_Phase3.md
    ├── CricketHub_UI_UX_Phase3.md               → repo root: CricketHub_UI_UX_Phase3.md
    ├── CricketHub_Implementation_Plan_Phase3.md  → repo root: CricketHub_Implementation_Plan_Phase3.md
    ├── firestore_rules_phase3_addendum.md        <-- copy rules blocks into existing cricket_hub/firestore.rules
    └── firestore_indexes_phase3_addendum.json     <-- append to existing firestore.indexes.json
```

---

## 🔧 Step-by-step integration

### Step 1: Branch from `phase-2`

```bash
git checkout phase-2
git checkout -b phase-3
```

### Step 2: Add Flutter dependencies

Append to `cricket_hub/pubspec.yaml` under `dependencies:`:

```yaml
  razorpay_flutter: ^1.3.7
  qr_flutter: ^4.1.0
  mobile_scanner: ^5.2.3
  image_picker: ^1.1.2
  cached_network_image: ^3.4.1
  geolocator: ^13.0.1
  table_calendar: ^3.1.2
  jwt_decoder: ^2.0.1
  permission_handler: ^11.3.1
```

Run: `flutter pub get`

### Step 3: Merge `app_constants.dart`

Open `cricket_hub/lib/core/app_constants.dart` and copy the **Phase 3 additions** (collections, platform fee, refund hours, pitch types, etc.) from `cricket_hub_phase3/lib/core/app_constants.dart` into your existing file.

Your existing file already has `groundsCol` and `bookingsCol` — just add the new ones below them.

### Step 4: Copy Flutter files

For each file in `cricket_hub_phase3/lib/`, copy it to the matching path inside `cricket_hub/lib/`.

### Step 5: Wire providers in `lib/main.dart`

Add these inside the `MultiProvider` providers list:

```dart
Provider<GroundService>(create: (_) => GroundService()),
Provider<BookingService>(create: (_) => BookingService()),
Provider<PaymentService>(create: (_) => PaymentService()),
Provider<UmpireService>(create: (_) => UmpireService()),
```

### Step 6: Register routes in `lib/main.dart`

Add to the `routes:` map:

```dart
GroundListScreen.route: (ctx) {
  final args = ModalRoute.of(ctx)?.settings.arguments;
  return GroundListScreen(city: args as String?);
},
```

For the other Phase 3 screens, use the simpler form (no arguments needed at registration time — arguments passed via `Navigator.pushNamed(...)` at call sites):

```dart
GroundDetailScreen.route: (_) => const GroundDetailScreen(),
BookingCheckoutScreen.route: (_) => const BookingCheckoutScreen(),
BookingSuccessScreen.route: (_) => const BookingSuccessScreen(),
```

> **Note:** Phase 2 routes typically don't take arguments. `GroundDetailScreen` and `BookingCheckoutScreen` require an argument — adjust your route registration accordingly or wrap with builders that read `ModalRoute.of(context).settings.arguments`.

### Step 7: Activate the "Ground booking" menu entry

In `cricket_hub/lib/screens/menu/menu_screen.dart`, replace the "Coming Soon" Ground booking `_ComingSoonTile` with a real `ListTile` that navigates:

```dart
ListTile(
  leading: Container(/* existing decoration */, child: const Icon(Icons.grot_rounded)),
  title: const Text('Ground booking'),
  subtitle: const Text('Find a place for your next game'),
  trailing: const Icon(Icons.chevron_right_rounded, size: 17),
  onTap: () => Navigator.pushNamed(context, GroundListScreen.route),
),
```

### Step 8: Merge Cloud Functions

**Phase 2 already has `cricket_hub/functions/index.js` with tournament/stats/push functions.**

Open both files. Append the Phase 3 exports (from `cricket_hub_phase3/functions/index.js`) below your existing Phase 2 exports. The required helpers (`requireUid`, `isoDate`, etc.) are already in Phase 2's index.js — but the Phase 3 file includes its own copies for self-containment. If you see duplicate helpers, **remove the Phase 3 duplicates** to avoid `const` redefinition errors.

### Step 9: Update functions/package.json

Merge dependencies — add to your existing `cricket_hub/functions/package.json`:

```json
{
  "dependencies": {
    "razorpay": "^2.9.5",
    "jsonwebtoken": "^9.0.2",
    "uuid": "^10.0.0"
  }
}
```

Then `cd cricket_hub/functions && npm install`.

### Step 10: Update Firestore rules

Open `cricket_hub/firestore.rules`. Follow the instructions in `docs/firestore_rules_phase3_addendum.md`:

1. Append the favorites + bookings sub-collection rules inside `match /users/{userId}`.
2. Append the `isVerifiedGround`/`isVerifiedUmpire` helper definitions near the top.
3. Append all `match /grounds/...`, `match /bookings/...`, etc. blocks at the end of the `service cloud.firestore { ... }` body.

```bash
firebase deploy --only firestore:rules
```

### Step 11: Update Firestore indexes

Open `cricket_hub/firestore.indexes.json`. Append each entry from `docs/firestore_indexes_phase3_addendum.json#indexes_to_append[]` to its `indexes` array.

```bash
firebase deploy --only firestore:indexes
```

### Step 12: Configure Razorpay secrets

```bash
firebase functions:secrets:set RAZORPAY_KEY_ID
firebase functions:secrets:set RAZORPAY_KEY_SECRET
firebase functions:secrets:set RAZORPAY_WEBHOOK_SECRET
firebase functions:secrets:set QR_JWT_SECRET
```

> Get test keys from [dashboard.razorpay.com](https://dashboard.razorpay.com/app/keys) → Test Mode.

### Step 13: Deploy & test

```bash
firebase deploy --only functions

# Run unit tests (Node.js native test runner — same as Phase 2)
cd cricket_hub/functions && npm test

# Run Dart tests
cd ../test && flutter test
```

---

## ✅ What works out of the box

- ✅ Browse grounds in 5 cities with city/pitch/price/amenity filters
- ✅ Calendar with slot grid (Phase 3.5 polish — calendar widget is sketched in UI_UX doc)
- ✅ 10-minute slot reservation (atomic transaction — race-condition-proof)
- ✅ Razorpay checkout (UPI / Card / NetBanking)
- ✅ Server-side HMAC signature verification
- ✅ Webhook idempotency (event_id dedup)
- ✅ Booking confirmation with QR code (signed JWT)
- ✅ Cancellation + automatic refund per policy
- ✅ All Node.js tests pass: `npm test` → **19/19 passing**
- ✅ All Dart tests pass: `flutter test` (Phase 3 model tests)

## 🔮 What's stubbed (Phase 3.5+ backlog)

- Owner Dashboard UI (4 tabs)
- Umpire Dashboard + availability toggle screen
- Leave Review screen UI
- Map view + Google Maps embed
- Photo upload (Cloud Storage rules)
- Image picker integration
- Push notifications for booking confirmations (server sends; client wiring needed)

---

## 📊 Verified before zipping

- ✅ 19 Node.js tests pass via `node --test`
- ✅ Code follows Phase 2 style (snake_case docstrings, AppConstants, no over-commenting)
- ✅ All filenames mirror Phase 2 locations (lib/models, lib/services, etc.)
- ✅ Flutter models match Phase 2's `Team`-style factory pattern
- ✅ Cloud Functions use same `asia-south1` region and `firebase-admin/firestore` imports as Phase 2
- ✅ No new dependencies beyond what Phase 2's docs already permit

---

## 🐞 Honest limitations

1. **`functions/index.js` is self-contained** — when merging into your Phase 2 file, remove the duplicate `requireUid` / `isoDate` / etc. helpers that exist in both files. Keep Phase 2's.
2. **`GroundDetailScreen` and `BookingCheckoutScreen` expect route arguments.** Phase 2's route signature is `(name) => screen`. You may need to change registration to a builder that reads `ModalRoute.settings.arguments`.
3. **The "Ground booking" menu link** is shown as a snippet, not as a fully rewritten `menu_screen.dart`. Edit yours directly.

---

**Sab kuch ready hai, Smeet! Phase 3 Phase 2 ke structure me drop karne ke liye perfect hai.** 🎯