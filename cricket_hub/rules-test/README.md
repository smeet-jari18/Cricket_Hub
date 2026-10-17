# Firestore Rules — verification suite

32 checks that run your **real `../firestore.rules`** against the Firebase
Firestore emulator, using the real client SDK. If these pass, the rules will
not surprise you in production.

## Requirements

- **Java 21+** (the Firestore emulator requires it)
  ```bash
  java -version   # must print 21 or higher
  ```
- `firebase-tools` — `npm install -g firebase-tools`

## Run

```bash
cd rules-test
npm install
npm test
```

Expected tail:

```
=== 32/32 checks passed ===
✔  Script exited successfully (code 0)
```

## What it covers

| # | Area | Checks |
|---|---|---|
| 0 | Phase-3 collections reachable at all | 6 |
| 1 | Unauthenticated callers locked out | 3 |
| 1b | Umpire `phone_number` not world-readable (BUG-12) | 2 |
| 2 | Grounds: verified+active vs draft; `isAdmin()` on/off | 5 |
| 2b | List query satisfies the rules (rules-are-not-filters) | 1 |
| 3 | Bookings visible to the two parties only | 4 |
| 4 | `payout_ledger/{uid}/weeks/{week}` path (BUG-11) | 3 |
| 5 | `users/{uid}/favorite_grounds` ownership | 2 |
| 6 | Reviews: own only, rating 1-5, no client delete | 4 |
| 7 | Phase 1/2 rules not regressed | 2 |

## Note

The suite seeds an `/admins/{uid}` document to prove `isAdmin()` works both ways —
deny-by-default when empty, allow when a doc exists.
