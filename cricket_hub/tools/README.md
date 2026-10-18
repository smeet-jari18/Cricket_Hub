# tools/ — emulator scripts

Teen chhote Python scripts (sirf standard library, koi `pip install` nahi).
Sab `firebase emulators:start` ke saath chalte hain.

```bash
# Terminal 1
firebase emulators:start

# Terminal 2
python3 tools/seed_emulator.py            # app me login karne ke liye demo data
python3 tools/e2e_smoke_test.py           # 24 checks — rules + booking + admin lifecycle
python3 tools/stress_test_booking.py -n 10   # slot race: exactly 1 winner
```

## Files

| File | Kya karta hai |
|---|---|
| `emulator_common.py` | Shared HTTP helpers: Auth emulator signup, Firestore REST (typed values), callable invocation, check-runner. |
| `seed_emulator.py` | Demo data: 3 users + `ground_demo_ahmedabad` (active+verified) + ek active umpire. UIDs print karta hai. |
| `e2e_smoke_test.py` | 24 assertions — **real ID tokens** se, yaani `firestore.rules` actually enforce hote hain. |
| `stress_test_booking.py` | N concurrent `createBookingHold` calls, same slot. 1 winner + N−1 `ABORTED` expect karta hai. |
| `sync_firebase_options.dart` | `lib/firebase_options.dart` ko `android/app/google-services.json` (+ iOS plist) se bhar deta hai. **Firebase CLI / flutterfire ke bina** — `dart run tools/sync_firebase_options.dart`. `--check` sirf report karta hai. |
| `check_cricapi.py` | Phase-4 CricAPI live smoke check — asli API ko ek request; key, quota aur response shape verify karta hai. Exit **0** = sab theek, **2** = key nahi di, **3** = key reject ya quota khatam, **4** = network ya payload badla. `--demo` se bina account failure path dikhta hai, `--json` CI ke liye. |
| `make_icons.py` | Ek source PNG (`assets/branding/logo_source.png`) se saare icons: splash asset, native launch logo, Android legacy + adaptive (har density), iOS AppIcon (alpha ke bina), web/PWA + favicon. `--check`, `--style on_teal`. |
| `l10n_coverage.py` | Localization coverage: kaunsi files migrated hain, kitne English literal bache. `--files` worst-first list, `--gate` migrated files me regression par exit 1. |
| `../rules-test/storage.test.js` | 19 Storage-rules checks (`grounds/…` + `umpires/…` upload/read/delete). `@firebase/rules-unit-testing` me Storage nahi hai, isliye seedha emulator REST API. **Sirf `/v0/` endpoint par rules lagti hain** — details `PHASE3_STATUS.md` §6.1. |

## Do tarah ke auth

* `Authorization: Bearer owner` → emulator ka **admin bypass**. Sirf seeding ke liye.
* `Authorization: Bearer <idToken>` → asli user. Har E2E assertion isi se jata hai.

## Fresh state

`e2e_smoke_test.py` aur `stress_test_booking.py` dono start me Firestore data
aur Auth users wipe karte hain (`fs_clear()` + `auth_delete_all()`), taaki
pichhle run ka "slot already booked" naya run na tode. Yaani baar-baar
chalane pe bhi same result.

## Note — concurrency limit

Har concurrent callable invocation ka apna Node runtime banta hai (~80 MB).
2 GB RAM wale machine pe ~10-12 se zyada concurrent calls emulator ko OOM kar
deti hain. `-n 50` ke liye 4+ GB RAM chahiye.
