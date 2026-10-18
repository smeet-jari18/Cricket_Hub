# Phase 4 — Analysis & Plan (docs vs code)

> Ye doc main branch ke `CricketHub_Implementation_Plan.md` + `CricketHub_PRD.md`
> ko `phase-3_update` (commit `feca5b0`) ke code se compare karke likha gaya hai.
> Phase 4 branch: **`phase-4`** (phase-3_update + P3 commit `7cf85cc` se bani).

---

## 1. Docs kya kehte hain (Phase 4 ka scope)

`CricketHub_Implementation_Plan.md` §4:

> **Phase 4: Pro Features & International Cricket (Months 10-12)**
> * Key Features: International Live Scores, Localization (Hindi, Tamil).
> * Tech Focus: REST API integrations (CricAPI), Flutter `intl` package for localization.

`CricketHub_PRD.md` Release Plan:

> **Phase 4** | Integration of CricAPI, International Match Center, Localization (Hindi, Tamil, etc.) | Month 10 - 12

User story jo is phase me band hoti hai:

| ID | Story | Acceptance criteria | Priority |
|---|---|---|---|
| US-10 | As a Fan, I want to view international cricket live scores so that I use CricketHub as my only cricket app. | Dedicated **"International" tab** pulling data from CricAPI | Could Have (P4) |

**Do hi deliverables hain, aur bas do:** (a) CricAPI + International Match Center,
(b) Localization Hindi/Tamil. Docs me "Pro Features" title hai par neeche koi
paid/subscription feature define nahi kiya gaya — isliye main subscription invent
nahi kar raha.

---

## 2. Code kahan khada hai (branch analysis)

| Cheez | Doc maangta hai | Code me aaj | Gap |
|---|---|---|---|
| International tab | Dedicated tab | **Nahi hai.** `NavigationBar` me 4 tabs: Home / My Cricket / Tours / Menu | Tab add karna hoga |
| International entry point | — | `menu_screen.dart` me `_ComingSoonTile('International scores')` — **dead button** | Isko asli screen se replace karna hai |
| CricAPI client | REST integration | **Zero.** `http` package bhi dependency me nahi tha | Naya service + model |
| API key config | — | **Koi nahi.** App me sirf Firebase config hai | `--dart-define=CRICAPI_KEY` |
| Localization | Hindi + Tamil | **Zero.** `flutter_localizations` nahi, ARB nahi, `intl` sirf date format ke liye (3 files) | Poora l10n infra |
| Hardcoded strings | — | `lib/` me **~3003 string literals**, 80 dart files | Extraction |
| Locale persistence | — | Nahi | `shared_preferences` |
| Locale switcher UI | — | Nahi | Menu me language picker |
| Tests | — | 107 Dart + 35 functions + 47 firestore rules + 19 storage rules | P4 ke naye tests |

### Achhi khabar — jo cheezein pehle se taiyar hain

* `provider` already hai → `LocaleProvider` usi pattern me fit ho jaata hai
  (koi naya state-management library nahi).
* `intl: ^0.20.3` already hai → `flutter_localizations` ka version clash nahi.
* Menu screen me "International scores" ka tile already design ho chuka hai —
  sirf `_ComingSoonTile` → `ListTile` + route.
* `cached_network_image` already hai → team logos ke liye kuch naya nahi chahiye.
* Theme (`AppTheme`) me poore colors hain → naye screens consistent rahenge.

### Baad me aane wali cheezein (is round me nahi)

| Cheez | Kyun nahi |
|---|---|
| Asli CricAPI data | Valid API key chahiye (`apikey=demo` → `Invalid API Key`). Code key ke bina **demo mode** me chalega, key milte hi live. |
| Baaki 80 files ki localization | ~2900 strings. Ek sprint ka kaam hai, ek turn ka nahi. Is round me infra + ek poora vertical (nav + menu + international + language screen) + coverage tool. |
| Store submission / TestFlight | Device + console chahiye (Phase 3 se pending). |

---

## 3. Is round ka scope (definition of done)

### P4-1 — International Match Center (US-10) — ✅ DONE
- [x] `models/intl_match.dart` — CricAPI response ka typed model (+ scorecard)
- [x] `services/cric_api_service.dart` — HTTP + TTL cache (5 min) + typed errors
      (no key / invalid key / rate limit / network / bad payload)
- [x] `services/cric_api_demo.dart` — bundled demo data, **usi parser se** guzarta hai
- [x] `screens/international/international_screen.dart` — Live / Upcoming / Recent
- [x] `screens/international/intl_match_detail_screen.dart` — scorecard
- [x] `MainShell` me 5th tab + menu ka dead tile → asli route
- [x] Tests: 26 service/model + 7 widget

### P4-2 — Localization (Hindi, Tamil) — ✅ infra + 1 vertical DONE
- [x] `l10n.yaml` + `lib/l10n/app_{en,hi,ta}.arb` + `flutter gen-l10n`
- [x] `providers/locale_provider.dart` — device locale → fallback → saved choice
- [x] `MaterialApp`: delegates, `supportedLocales`, `locale`, resolution callback
- [x] `screens/settings/language_screen.dart` — language picker
- [x] Localized: nav shell, quick-actions sheet, menu screen, international
      screens, language screen
- [x] Tests: 5 l10n + 10 locale-provider
- [x] `tools/l10n_coverage.py` — kitne strings baaki hain, file-wise + `--gate`

### Jo is round me **nahi** hoga (honest)
- Asli CricAPI live data ka proof — key nahi hai. Fixtures + graceful error path
  verified honge, live data nahi.
- Poori app ki localization — sirf infra + ek vertical.

---

## 4. Verification plan

| Check | Kaise |
|---|---|
| `flutter analyze` | 0 issues |
| `flutter test` | 107 + naye |
| International parsing | real-shape fixture JSON (CricAPI docs ke response format pe) |
| Error paths | 401/403/429/timeout/malformed sab tests me |
| l10n completeness | Dart test jo teeno ARB compare kare |
| Live API | `python3 tools/check_cricapi.py` — key ke saath; key ke bina honest "no key" |

---

## 5. Verification — kya sach me chala (is round)

| Check | Result |
|---|---|
| `flutter analyze` | ✅ **No issues found!** |
| `flutter test` (poora) | ✅ **155/155** (107 P3 + 48 naye) |
| `tools/l10n_coverage.py --gate` | ✅ **PASS** — har migrated file clean |
| `tools/check_cricapi.py` | ✅ live API hit chala; key ke bina exit 2, galat key par exit 3 (`Invalid API Key` — real response) |
| `flutter gen-l10n` | ✅ 4 generated files, 3 locales |
| Functions / Firestore rules / Storage rules | ✅ untouched is round (35/35, 47/47, 19/19 pichhle round se) |

### Kya *nahi* verify hua (honest)
- **Asli CricAPI data se screen nahi bhari** — key nahi hai. Jo verify hua:
  (a) real API tak pahunch kar error handling live check se, (b) parsing
  fixtures se, (c) UI states widget tests se. Live scores ka final proof key
  aane par ek run me mil jaayega: `flutter run --dart-define=CRICAPI_KEY=...`.
- **Device pe Hindi/Tamil rendering** — DejaVu/Noto font glyph coverage device
  pe dekha jaana chahiye. Flutter tests text match karte hain, glyph shapes nahi.
- **Tab bar 5 items** — NavigationBar 5 tak support karta hai, par chhoti
  screens pe label ellipsis manual check chahiye.

## 6. Aage kya (priority order)

| # | Kaam | Kyun abhi baki hai |
|---|---|---|
| 1 | Baaki ~81 files ki localization | Har file ~2-15 strings. `tools/l10n_coverage.py --files` se worst-first list milti hai; `--gate` regression rokta hai |
| 2 | CricAPI key + `flutterfire configure` | Aapke paas account/key chahiye (`cricapi.com`, free 100 hits/day) |
| 3 | CricAPI proxy Cloud Function | Key APK me nahi jaani chahiye — production me Blaze + Functions proxy, phir `CRICAPI_KEY` client se hata do |
| 4 | Live scores ka polling/refresh | Abhi manual pull-to-refresh + 5 min cache. Live match ke liye 60 s auto-refresh (quota ke saath) |
| 5 | Device pe integration test | Phase 3 se pending |
| 6 | Razorpay | Aapka explicit decision — abhi bhi untouched |

---

## 7. Hotfix — device pe black screen (`[core/duplicate-app]`)

**Report:** `flutter run` on CPH2213 → `Unhandled Exception: [core/duplicate-app] A Firebase App named "[DEFAULT]" already exists` at `main.dart:99` → black screen.

### Root cause (chain, har link verify kiya)

| # | Fact | Kahan se |
|---|---|---|
| 1 | `android/app/build.gradle.kts` me `com.google.gms.google-services` plugin laga hua hai | file |
| 2 | `google-services.json` maujood hai → Android process start par `[DEFAULT]` FirebaseApp **khud** bana deta hai, **asli** apiKey ke saath | plugin behaviour |
| 3 | Repo/zip ki `lib/firebase_options.dart` ek **placeholder** hai (`AIzaSyPLACEHOLDER-…`) | file |
| 4 | `Firebase.initializeApp(options: placeholder)` → naam wahi, options alag → `IllegalStateException` → Dart me `[core/duplicate-app]` | Firebase Android SDK |
| 5 | Wo exception `main()` me **unguarded** thi → `runApp()` kabhi chala hi nahi → black screen | `main.dart` |

"Pehle workable tha" ki wajah: aapki machine pe asli `firebase_options.dart` thi (gitignored). Zip me placeholder aata hai, usne overwrite kar diya.

### Fix

* `lib/core/firebase_bootstrap.dart` (naya) — init se pehle dekhta hai native app
  bana hua hai kya; agar haan to **usi ko adopt** karta hai. `duplicate-app`
  race ke liye do fallback: dobara app-list check, phir
  `Firebase.initializeApp()` **bina options** (jo native app se attach ho jaata hai).
* `lib/screens/bootstrap_error_screen.dart` (naya) — agar init phir bhi fail ho
  to **black screen nahi**, ek readable error screen + exact fix steps.
* `main()` me Firebase ke baad ka startup (Firestore settings, notification
  init) bhi try/catch me — koi bhi failure error screen par girta hai.
* Placeholder `firebase_options.dart` ka header ab poori kahani likhta hai.
* `README.md` me "Device pe black screen?" section.

### Verify

| Check | Result |
|---|---|
| `flutter analyze` | ✅ 0 issues |
| `flutter test` | ✅ **169/169** (+10 bootstrap, +4 error-screen) |
| Duplicate-app scenario (unit) | ✅ native app adopt hota hai, `initialize` call hi nahi hota |
| Plugin-race scenario (unit) | ✅ options-free attach fallback |
| Error path | ✅ error screen render, technical detail expander me |

**Jo verify nahi hua:** asli device pe dobara run. Sandbox me Android device
nahi hai — ye aapko confirm karna hoga (`flutter clean && flutter run`).

---

## 8. Localization — ab poora ho gaya (is round)

§3 me maine likha tha "baaki ~81 files ki localization ek sprint ka kaam hai, ek
turn ka nahi". Wo baat aadhi sach thi: **haath se** 500 strings migrate karna
sprint hai, par 90% kaam mechanical hai — aur mechanical kaam script ka hota hai.
Is round me wahi kiya.

### Pipeline (sab `tools/` me, sab `--dry-run` support karte hain)

| Tool | Kaam |
|---|---|
| `l10n_sweep.py` | `phrasebook_*.json` (English → hi, ta) padhta hai, har **text slot** (`Text(`, `label:`, `hintText:`, `title:`, `content:` …) me exact match dhoondh ke `l10n.<key>` kar deta hai. Firestore field keys, route names, asset paths ko chhoota hi nahi. Key deterministic hai (`slugify`) aur agar wahi English pehle se ARB me hai to wahi key reuse hoti hai |
| `l10n_final_pass.py` | Jo chیز flat lookup se nahi hoti: **(a)** `'first half ' 'second half'` — poora jumla ek key me join, **(b)** `'Could not save: $e'` — ARB *placeholder* + `@key` metadata, taaki value silently drop na ho |
| `l10n_coverage.py` | Naapta hai: kitni files migrated, kitne literals bache. `--gate` fail hota hai agar koi migrated file piche hate. `EXEMPT` me har file ki wajah likhi hai aur gate use har run pe print karta hai |
| `l10n_decl_fix.py` | Analyzer ke `Undefined name 'l10n'` se enclosing method dhoondh ke `final l10n = …` daalta hai — sirf wahan jahan `context` reachable hai. Baaki manually |
| `l10n_fix_consts.py` | Codemod ke baad aane wale `invalid_constant` burst ko fix karta hai |

### Numbers (before → after)

| | Pehle | Ab |
|---|---|---|
| UI literals (whole app) | **566** | **0** (1 exempt file, reason gate me likha) |
| Files importing l10n | 0 → 17 (wave 1) | **48** |
| ARB keys | 84 | **528** × en/hi/ta |
| `l10n_coverage.py --gate` | — | ✅ **PASS** |

### Kya genuinely translate hua

- **Har screen**: auth (login, OTP, profile setup), home, my cricket, career
  stats, ground list/detail/calendar, booking (checkout, detail, success,
  review), owner (dashboard, create/edit ground, calendar, earnings, QR
  scanner), umpire (list, detail, booking, requests, dashboard, edit,
  onboarding, availability), tournament (list, create, detail — 49 strings
  wala sabse bada file), match (create, toss, live, scoring dashboard),
  admin verification, menu, language picker, offline banner, notifications.
- **ICU plurals** jahan pehle `'${n} team${n == 1 ? '' : 's'}'` hack tha:
  teams, bookings, reviews, slots, runs.
- **Placeholders** har jagah jahan value thi: `Could not save: {error}`,
  `{a} vs {b}`, `Need {runs}`, `Round {round}`, `₹{rate}/hr` …
- **1 bug bhi mila**: home hero ka `'Your ground.\\nYour game.'` double-escaped
  tha — screen pe literally `\n` dikh raha tha. Ab `homeHeroTitle` key se aata
  hai aur asli line break deta hai.

### Gate kaise chalta hai

```bash
python3 tools/l10n_coverage.py          # summary
python3 tools/l10n_coverage.py --files  # worst-first
python3 tools/l10n_coverage.py --gate   # CI: exit 1 on regression
```

`test/l10n_test.dart` me ek naya test bhi hai: **koi bhi ARB key jo app me
kahin use nahi hoti, test fail kar deti hai** — dead translations jamne se
rokta hai.

### Jo verify nahi hua (honest)

- **Translator review nahi hui.** Hindi/Tamil maine likhi hain — technical terms
  (NRR, strike rate, bye, wide) cricket ke common form me rakhe hain, par kisi
  native reviewer ne inhe padha nahi hai. Production se pehle ek review round
  chahiye.
- **Layout**: Tamil/Hindi strings English se lambi hoti hain. Widget tests
  text overflow nahi pakadte. Device pe ek visual pass baaki hai.
- `bootstrap_error_screen.dart` jaan-boojh ke English hai: wo Firebase fail
  hone par chalta hai, `AppLocalizations` par depend nahi kar sakta (test isko
  enforce karta hai).

---

## 9. Localization ke baad ki safety (is round)

Localization "done" ka matlab ye nahi ki layout bhi theek hai. Devanagari aur
Tamil Latin se chaudi hoti hain aur translations English se lambi — aur Flutter
me `RenderFlex overflowed` ek **painted warning** hai, exception nahi, isliye
normal widget test use pakadta hi nahi.

**`test/locale_layout_test.dart`** (8 tests):

- Har case **320 × 640** (chhota phone) aur **text scale 1.3×** (bada font
  chahiye wale user) par chalta hai, teeno languages me.
- Language picker (en/hi/ta) aur International screen (no-key state + live
  match cards with long venue) — `tester.takeException()` null hona chahiye.
- Ek **control test** bhi hai jo jaan-boojh ke overflow karta hai aur assert
  karta hai ki harness use pakadta hai. Warna safety net "rumour" hota hai.

**`test/l10n_test.dart`** me ek naya tripwire: koi bhi translation apne English
se **2.2×** se lambi nahi honi chahiye (aaj ka worst 1.89× hai). Ye purani
strings par lint nahi, **nayi** strings pakadne ke liye hai.

### CricAPI key — ship se pehle check

`tools/check_cricapi.py` pehle se tha (exit codes 0/2/3/4 documented the).
Is round me usme `--demo` aur `--json` add kiye, aur **network failure par
traceback** ki jagah saaf message + exit 4. Teen paths asli execution se
verify hue:

| Path | Kaise | Result |
|---|---|---|
| Key nahi di | `python3 tools/check_cricapi.py` | exit **2** |
| Key galat | `--demo` (asli API call) | exit **3**, "Invalid API Key" |
| Network dead | `--base https://no-such-host.invalid/...` | exit **4**, koi traceback nahi |
| Key sahi | — | **verify nahi hua** (asli key mere paas nahi) |

**Jo verify nahi hua:** exit 0 wala success path. Jab aapki key aa jaaye,
`python3 tools/check_cricapi.py --key ...` chala kar ek baar dekh lena.
