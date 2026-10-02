# 🏏 CricketHub — Phase 1 (MVP Starter Code)

Flutter + Dart + Firebase app for local cricket: teams, matches,
**offline-first ball-by-ball scoring**, and live scores for fans.

Built from: `CricketHub_PRD.md`, `CricketHub_TRD.md`, `CricketHub_AppFlow.md`,
`CricketHub_Backend_Schema.md`, `CricketHub_Security_Access.md`, `CricketHub_UI_UX_Guidelines.md`

**Team:** Smeet Jariwala, Aman Sinha
**Stack:** Flutter • Dart • Firebase (Auth + Firestore) • Provider • dark theme

---

## ⚡ What is included (Phase 1)

| Feature | Status |
|---|---|
| Phone OTP + Google login (Firebase Auth) | ✅ Working code |
| Profile setup (name, batting/bowling style) | ✅ Working code |
| Create team + add players to roster | ✅ Working code |
| Create match (teams, overs) | ✅ Working code |
| Toss screen (bat/bowl decision) | ✅ Working code |
| **Scoring engine** (runs, extras, wickets, strike rotation, undo) | ✅ **Fully unit tested** |
| Scoring Dashboard (big buttons, offline banner, dialogs) | ✅ Working code |
| Ball-by-ball sync to Firestore (works OFFLINE) | ✅ Working code |
| Live Match Center (real-time header + commentary tab) | ✅ Working code |
| Career stats / scorecards / tournaments | ⏳ Phase 2 (Cloud Functions) |
| Ground / umpire booking, payments | ⏳ Phase 3 |

---

## 🚀 Setup — Step by Step (do these in order!)

### Step 1 — Install Flutter (if not done)
Download: https://docs.flutter.dev/get-started/install
Check it works:
```bash
flutter doctor
```

### Step 2 — Create the platform folders
This ZIP contains the source code (`lib/`, `test/`, `pubspec.yaml`).
Generate the Android/iOS folders (takes 1 minute — it will NOT overwrite our code):
```bash
cd cricket_hub
flutter create .
flutter pub get
```

### Step 3 — Connect Firebase
```bash
# install the CLI once
npm install -g firebase-tools
firebase login

dart pub global activate flutterfire_cli
flutterfire configure
```
`flutterfire configure` will ask you to:
1. Select/create a Firebase project (e.g. `crickethub-dev`)
2. Select platforms: **android** (+ ios if you have a Mac)

This creates `lib/firebase_options.dart` automatically.

### Step 4 — Turn on Login methods
Firebase Console → your project → **Authentication → Sign-in method**:
1. Enable **Phone** (for OTP)
2. Enable **Google**

**Android phone-auth extra step (important!):**
Firebase Console → Project Settings → Your Android app → add **SHA-1 fingerprint**:
```bash
cd android && ./gradlew signingReport   # copy the SHA-1 of debugVariant
```
Paste SHA-1 in Firebase Console, then re-download `google-services.json`
and put it in `android/app/`.

### Step 5 — Firestore Database
Firebase Console → **Firestore Database** → Create database → Start in
**test mode** (we replace with real rules below).

Then copy the rules from `CricketHub_Security_Access.md v1.2`
into Firestore → Rules → Publish. (The doc's rules are exactly what
this code expects: only `scorer_uid` can update a live match.)

### Step 6 — Run it!
```bash
flutter run
```

### Step 7 — Run the scoring engine tests
```bash
flutter test
```
20+ tests verify the cricket rules (strike rotation, wides, no-balls,
byes, wickets, undo, over completion...). **All must pass.** 🟢

---

## 📁 Project Structure

```
lib/
├── main.dart                  # app entry, routes, providers
├── core/
│   ├── app_theme.dart         # ALL colors/theme (match your Stitch design here!)
│   └── app_constants.dart     # collection names, defaults
├── models/                    # data classes = Backend_Schema.md
│   ├── app_user.dart          # users collection
│   ├── team_model.dart        # teams collection
│   ├── match_model.dart       # matches collection
│   └── ball_event.dart        # balls subcollection
├── services/                  # ALL Firebase calls live here
│   ├── auth_service.dart      # OTP, Google, profile
│   ├── team_service.dart      # teams CRUD
│   └── match_service.dart     # matches + ball sync (WriteBatch)
├── providers/
│   ├── auth_provider.dart     # login state for whole app
│   ├── scoring_engine.dart    # ⭐ PURE cricket logic (tested!)
│   └── scoring_provider.dart  # engine + Firestore connection
├── screens/
│   ├── splash_screen.dart
│   ├── auth/ (login, otp, profile_setup)
│   ├── home/ (main_shell with bottom nav, home, my_cricket)
│   ├── team/ (create_team)
│   ├── match/ (create_match, toss, scoring_dashboard ⭐, live_match)
│   └── menu/
└── widgets/ (score_button, live_match_card, offline_banner)

test/
└── scoring_engine_test.dart   # 20+ unit tests of cricket rules
```

## 🎨 Matching your Stitch design
All colors, fonts and shapes are in **ONE file**: `lib/core/app_theme.dart`.
Change the hex codes there and the whole app re-skins instantly.
(Current values = your UI/UX Guidelines: teal #00BFA5, orange #FF6D00, dark #121212.)

## 📋 Known v1 limitations (planned, not bugs)
- One innings per match session (full 2-innings chase flow → Sprint 4/Phase 2)
- Roster uses player names (UID-based roster + invite links → Phase 2)
- Batsmen-level live stats in Match Center → Sprint 4
- Byes/leg-byes: enter runs via prompt (auto-detection of overthrows → Phase 2)

## 🔒 Security reminder
The app trusts Firestore Security Rules completely. Before ANY public
testing, replace test-mode rules with `CricketHub_Security_Access.md v1.2`.
