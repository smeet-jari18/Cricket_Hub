# Technical Requirements Document (TRD) — Phase 3 Addendum: CricketHub

> **Scope:** Extends `CricketHub_TRD.md` (v1.0) with the **Marketplace & Bookings** architecture, third-party integrations (Razorpay, JWT signing), slot reservation algorithm, and webhook idempotency.

## Document Info
| Attribute | Details |
| :--- | :--- |
| **Project Name** | CricketHub |
| **Document Version** | 3.0.0 (Phase 3 Addendum) |
| **Date** | October 2, 2026 |
| **Phase** | 3 of 4 |

---

## 1. Phase 3 Architecture Additions

The Marketplace layer introduces three new server-side concepts on top of the existing Flutter + Firebase stack:

1. **Slot Reservation Engine** — Firestore-transaction-based lock to prevent double-booking.
2. **Razorpay Payment Bridge** — Cloud Functions orchestrating the full payment lifecycle.
3. **QR Token Service** — Server-signed JWTs for in-person booking verification.

### High-Level Phase 3 Data Path
```
[Flutter Client]
  │  HTTPS callable: createRazorpayOrder(bookingId)
[Cloud Function: createRazorpayOrder]
  │  ── validates booking.status === 'held'
  │  ── Razorpay REST: orders.create({amount, currency:'INR', notes:{booking_id}})
  │  ── saves order_id on booking doc
  ▼
[Razorpay SDK opened in Flutter]
  │  User pays → SDK returns {payment_id, order_id, signature}
  ▼
[Flutter Client]
  │  HTTPS callable: verifyRazorpayPayment(...)
[Cloud Function: verifyRazorpayPayment]
  │  ── HMAC_SHA256(secret, order_id|payment_id) === signature?
  │  ── booking.status → 'confirmed', slot.status → 'booked'
  │  ── write qr_token JWT
  │  ── onBookingConfirmed trigger → FCM + payout_ledger pre-write
```

---

## 2. Technology Stack (Phase 3 additions)

### Flutter (pubspec.yaml additions)
```yaml
dependencies:
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

### Cloud Functions (functions/package.json additions)
```json
{
  "dependencies": {
    "razorpay": "^2.9.5",
    "jsonwebtoken": "^9.0.2",
    "uuid": "^10.0.0"
  }
}
```

### Firebase Services
- Firebase Cloud Storage — ground photos and umpire certification PDFs.
- Firebase Cloud Functions v2 — add `onSchedule`, `onRequest`, `onCall`.
- App Check — recommended for `enforceAppCheck: true` on the new callable functions.

---

## 3. Slot Reservation Algorithm

**Critical correctness requirement:** Two users must not be able to reserve the same slot simultaneously.

### Algorithm (Firestore Transaction)
```
BEGIN TRANSACTION
  slotRef = grounds/{groundId}/slots/{dateIso}
  slotDoc = transaction.get(slotRef)

  IF slotDoc == NULL
      transaction.create(slotRef, generateSlotsForDate(ground))
  END

  currentSlotEntry = slotDoc.slots[slotKey]

  IF currentSlotEntry.status == 'available' OR
     (currentSlotEntry.status == 'held' AND currentSlotEntry.held_by == organizerUid AND currentSlotEntry.held_until < now)
    transaction.update(slotRef, {
      slots[slotKey]: {
        status: 'held',
        held_by: organizerUid,
        held_until: now + 10 minutes,
        booking_id: newBookingId
      }
    })
    booking.status = 'held'
    RETURN success
  ELSE
    RETURN failure('Slot unavailable')
END TRANSACTION
```

The slot is moved to `held` for 10 minutes. If the user does not pay within that window, the scheduled function `expireStaleHolds` (every 5 minutes) scans `grounds/*/slots/{date}` and reverts any `held` entry with `held_until < now` back to `available`.

### Why this design?
- **No race condition** — Firestore transactions guarantee get-then-write atomicity per document.
- **Cost-efficient** — only one write per slot per attempt.
- **Idempotent on retry** — re-attempting with same `organizer_uid` within hold window returns the existing booking.

---

## 4. Razorpay Integration Architecture

### Why Cloud Functions + Flutter plugin (not pure Flutter REST)?
1. Server-side signature verification requires `RAZORPAY_KEY_SECRET`. Shipping that to the client would allow forged payments.
2. Webhook processing must happen on a server with our `RAZORPAY_WEBHOOK_SECRET`.
3. Atomicity — we need to atomically create the order + update booking's `razorpay_order_id` + check inventory.

### Razorpay Configuration
Set via Firebase Secret Manager:
```bash
firebase functions:secrets:set RAZORPAY_KEY_ID
firebase functions:secrets:set RAZORPAY_KEY_SECRET
firebase functions:secrets:set RAZORPAY_WEBHOOK_SECRET
```

### SDK Initialization (Flutter side)
```dart
import 'package:razorpay_flutter/razorpay_flutter.dart';

final _razorpay = Razorpay();
_razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
_razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
_razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

void openCheckout({
  required String orderId,
  required String keyId,
  required int amountInPaise,
  required String bookingId,
}) {
  var options = {
    'key': keyId,
    'amount': amountInPaise,
    'name': 'CricketHub',
    'order_id': orderId,
    'description': 'Booking $bookingId',
    'prefill': { 'contact': phone, 'email': email },
    'theme': { 'color': '#006B5C' },
    'notes': { 'booking_id': bookingId },
  };
  _razorpay.open(options);
}
```

### Webhook Idempotency
Every webhook event stored in `razorpay_events/{event_id}` (doc ID = Razorpay's event_id). The handler:
1. Writes event doc with `processed=false`.
2. If doc already exists, returns immediately (200 OK).
3. Processes the event inside a Firestore transaction.
4. Sets `processed=true`.

Razorpay retries are safe.

---

## 5. QR Token Service

### Why JWT instead of plaintext QR?
A plaintext `booking_id` could be guessed or forged. A JWT signed with our `QR_SECRET` cannot.

### Token Shape
```json
{
  "booking_id": "Bk_abc123",
  "ground_id": "Gr_xyz789",
  "organizer_uid": "uid_xxx",
  "date": "2025-04-15",
  "slot_start": "07:00",
  "slot_end": "09:00",
  "iat": 1748449600,
  "exp": 1748453200
}
```

- Signed with HS256 + `QR_SECRET`.
- Expires 1 hour after slot end.

### Owner Validation
Owner scanner Flutter screen calls Cloud Function `validateBookingQR`, which:
1. Verifies JWT signature.
2. Looks up `bookings/{booking_id}` and asserts `counterparty_uid == auth.uid`.
3. Confirms `status == 'confirmed'`.
4. Returns `{valid: true, booking: {...}}`.

---

## 6. New Cloud Functions (Phase 3)

| Function Name | Trigger | Purpose |
| :--- | :--- | :--- |
| `createBookingHold` | `onCall` | Atomically reserves slot, creates booking |
| `createRazorpayOrder` | `onCall` | Creates Razorpay order, validates hold |
| `verifyRazorpayPayment` | `onCall` | Verifies signature, confirms booking |
| `razorpayWebhook` | `onRequest` | Webhooks (signature-verified, idempotent) |
| `expireStaleHolds` | `onSchedule` (every 5 min) | Releases stale holds |
| `onBookingConfirmed` | `onDocumentUpdated` | FCM + payout_ledger pre-write |
| `onBookingCancelled` | `onCall` | Refund per policy |
| `aggregateGroundRating` | `onDocumentCreated` (review) | Recomputes aggregate |
| `weeklyPayoutDigest` | `onSchedule` (Mon 09:00 IST) | Weekly payout aggregation |
| `validateBookingQR` | `onCall` | JWT verify, returns booking |

---

## 7. New Firestore Composite Indexes

- `grounds` by `city + pitch_type + price_weekday_hourly + avg_rating`
- `grounds` by `status + verified + avg_rating`
- `bookings` by `organizer_uid + created_at DESC`
- `bookings` by `counterparty_uid + date ASC`
- `umpires` by `city + verified + avg_rating`
- `ground_reviews` by `ground_id + created_at DESC`

---

## 8. Cost & Performance Budget

### Cost targets
- **Per booking:** ≤ 30 reads + 8 writes (slot reservation + booking create + payment verify + onBookingConfirmed).
- **Per ground browse page:** ≤ 15 reads.
- **Webhook traffic:** Razorpay sends 3 events per payment, all idempotent.

### Performance targets
| Stage | Target (P95) |
| :--- | :--- |
| Ground list query | ≤ 800 ms |
| Slot loader | ≤ 600 ms |
| Razorpay order creation (server) | ≤ 1000 ms |
| Payment verification (server) | ≤ 500 ms |
| Webhook → booking update | ≤ 3 seconds |
| QR scanner → validate response | ≤ 1.5 seconds |

---

## 9. Caching Strategy (Phase 3)

| Asset | Cache | TTL |
| :--- | :--- | :--- |
| Ground listing page (per filter) | In-memory + disk (Hive) | 5 min |
| Ground photos | `cached_network_image` (disk) | 30 days |
| Slot data per date | In-memory (Flutter) | 60 sec |
| User's own bookings | Firestore snapshot (live) | Live |
| Owner dashboard earnings | `payout_ledger` snapshot | 1 hour |

---

## 10. Error Handling & Observability

- All Cloud Functions log structured JSON: `{function, requestId, uid, status, error}`.
- Crashlytics on Flutter side for client errors during checkout.
- Razorpay errors flow: Flutter catches via `EVENT_PAYMENT_ERROR` → user-friendly message + retries.
- Webhook failures trigger Razorpay's automatic retry; idempotency makes this safe.

---

## 11. Testing Strategy (Phase 3)

### Unit Tests (Cloud Functions)
- **Slot reservation:** 100% coverage on race conditions, hold expiry, double-booking prevention.
- **Refund calculation:** 100% coverage on time-to-slot buckets.
- **JWT signing/verification:** round-trip + tamper rejection.

### Integration Tests (Flutter)
- End-to-end: search ground → book → pay → see QR (Razorpay test mode).
- QR scan flow with seeded booking.

### Manual Test Cases
- **Concurrent booking:** Open same slot in 2 devices; only one wins.
- **Webhook replay:** Send same webhook twice; booking state stays consistent.
- **Refund window boundaries:** Test at exactly 24h, 12h, 0h before slot.

---

## 12. Security & Compliance Notes (Phase 3)

- **PCI compliance:** Razorpay SDK handles card capture. CricketHub never sees PAN/CVV.
- **RBI guidelines:** No card data stored. Only `razorpay_payment_id` token.
- **PII minimization:** Encrypted phone numbers via rules; bank refs only on server.
- **Audit logs:** All booking state changes logged to `bookings/{id}/audit/{logId}` with `actor_uid`.

---

*End of Phase 3 TRD Addendum.*