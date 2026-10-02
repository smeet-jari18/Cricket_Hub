# Security & Access Control — Phase 3 Addendum: CricketHub

> **Scope:** Extends `CricketHub_Security_Access.md` (v1.2) with Phase 3 Marketplace rules — Grounds, Bookings, Umpires, Reviews, Payouts.

## Document Info
| Attribute | Details |
| :--- | :--- |
| **Project Name** | CricketHub |
| **Document Version** | 3.0.0 (Phase 3 Addendum) |
| **Date** | October 2, 2026 |
| **Phase** | 3 of 4 |

---

## New Role-Based Access Control (RBAC) — Phase 3

| Role | Phase 3 Permissions |
| :--- | :--- |
| **Ground Owner** | CRUD own `grounds/{id}` (only when `owner_uid == self`). Write own `grounds/{id}/slots/{date}` and `blocked_rules`. Read own `bookings`. Scan & validate booking QR. |
| **Umpire** | CRUD own `umpires/{uid}` doc (only when `user_uid == self`). Update own `umpires/{uid}/availability/{date}`. Update `bookings/{id}.status` for incoming requests (accept/decline). |
| **Organizer / Player** | Read all `grounds` and `umpires` (only `active + verified`). Create `bookings` (own `organizer_uid`). Read own `bookings`. Write own `favorite_grounds/*` and `bookings/*`. |
| **Platform Admin** | Read/write all docs. Verify grounds/umpires. Issue refunds. |

---

## Firestore Rules

The complete Phase 1+2+3 rules block is in `firestore_rules_phase3_addendum.md`. Copy each `match /...` block into your existing `cricket_hub/firestore.rules`.

---

## Razorpay-Specific Security Considerations

1. **`RAZORPAY_KEY_SECRET`** stored in Firebase Secret Manager. Never shipped to clients.
2. Flutter only receives `RAZORPAY_KEY_ID` (public) via `createRazorpayOrder` response.
3. Every payment verification uses server-side HMAC:
   ```
   expected_signature = HMAC_SHA256(
     key: RAZORPAY_KEY_SECRET,
     data: razorpay_order_id + "|" + razorpay_payment_id
   )
   ```
   Reject if `expected_signature !== razorpay_signature`.
4. Webhook signature header `X-Razorpay-Signature` verified using **webhook-specific secret**.
5. All Razorpay events idempotent — stored in `razorpay_events/{event_id}` with `processed=false`.
7. `RAZORPAY_REFUND` API called server-side only.

---

## PII Protection (Phase 3)

- **Ground owner phone numbers:** Never stored on `grounds/{id}` doc. Resolved server-side in Cloud Functions.
- **Umpire phone numbers:** Stored on `umpires/{uid}.phone_number` but blocked from public reads via rules.
- **Bank details:** Stored on `users/{uid}.payout_bank_ref`. Never returned to clients.

---

## Custom Claims Setup (Phase 3)

```javascript
// Admin SDK (Cloud Functions only):
admin.auth().setCustomUserClaims(uid, { admin: true });

// Ground owner claim (set when user first creates a ground):
admin.auth().setCustomUserClaims(uid, { ground_owner: true });
```

---

## Threat Model — Phase 3

| Threat | Mitigation |
| :--- | :--- |
| Booking a slot without paying | Booking must transition `held → pending_payment → confirmed` only via verified Razorpay payment |
| Self-booking + self-review | Reviews require `booking_id`; Cloud Function verifies booking.status==='completed' |
| Modifying other owner's slot prices | Rules allow only `owner_uid == auth.uid` |
| Fake ground listings | Status starts `'draft'`; only after admin verification does `status='active'` |
| Replay of webhook | `razorpay_events` collection dedupes by event_id |
| Counterfeit QR codes | QR contains server-signed JWT (`qr_token`) |

---

*End of Phase 3 Security Addendum.*