# Backend Database Schema (Firestore) — Phase 3 Addendum: CricketHub

> **Scope:** Extends `CricketHub_Backend_Schema.md` (v1.1) with the **Phase 3 Marketplace collections**.

## Document Info
| Attribute | Details |
| :--- | :--- |
| **Project Name** | CricketHub |
| **Document Version** | 3.0.0 (Phase 3 Addendum) |
| **Date** | October 2, 2026 |
| **Database Type** | Firestore (NoSQL) |
| **Phase** | 3 of 4 |

---

## Architecture Note (Phase 3)

- **Cost discipline continues:** Listing pages read only the master doc; slot reads happen per day.
- **Slot reads paginated** server-side by date range.
- **Bookings write-heavy** — write path uses transactions to prevent double-booking.

---

## 7. Collection: `grounds` (NEW)

**Purpose:** Master record for every listed cricket ground.
**Document ID:** `{ground_id}` (Firestore auto-generated)

| Field Name | Data Type | Description |
| :--- | :--- | :--- |
| `name` | String | "Suncity Turf Park A" |
| `owner_uid` | String | UID of the user who created the listing |
| `city` | String | "Ahmedabad" |
| `address` | String | Full street address |
| `lat` | Number | Latitude (map view) |
| `lng` | Number | Longitude |
| `pitch_type` | String | `"turf"` \| `"matting"` \| `"concrete"` |
| `amenities` | Array of String | `["floodlights", "pavilion", "parking", "change_room"]` |
| `photos` | Array of String | Storage URLs (max 10) |
| `cover_photo_url` | String | Storage URL |
| `price_weekday_hourly` | Number | INR — weekday hourly rate |
| `price_weekend_hourly` | Number | INR — weekend hourly rate |
| `price_full_day` | Number | INR — full-day rate (optional) |
| `open_time` | String | "06:00" 24h |
| `close_time` | String | "22:00" 24h |
| `slot_duration_minutes` | Number | Default `120` |
| `status` | String | `"draft"` \| `"pending_verification"` \| `"active"` \| `"paused"` \| `"banned"` |
| `verified` | Boolean | Admin verification flag |
| `avg_rating` | Number | Cached aggregate |
| `review_count` | Number | Cached |
| `booking_count` | Number | Cached |
| `ground_stats` | Map | `{ total_bookings, total_revenue_paise, last_booked_at }` |
| `created_at` | Timestamp | Server timestamp |
| `updated_at` | Timestamp | Server timestamp |

### Sub-collection: `grounds/{ground_id}/slots/{date_iso}`
**Document ID:** `"2025-04-15"` (YYYY-MM-DD)

| Field Name | Data Type | Description |
| :--- | :--- | :--- |
| `date` | String | "2025-04-15" |
| `slots` | Map | Key = `"HH:mm-HH:mm"`, Value = `SlotEntry` |
| `blocked` | Boolean | Whole-day owner block |
| `block_reason` | String | Optional note |
| `generated_at` | Timestamp | When slot doc was created |
| `updated_at` | Timestamp | Last modified |

**SlotEntry** (value inside the `slots` map):
```json
{
  "status": "available" | "held" | "booked" | "blocked",
  "held_by": "<uid>",
  "held_until": "<ts>",
  "booking_id": "<id>",
  "match_id": "<id>"
}
```

---

## 8. Collection: `bookings` (NEW)

**Purpose:** Every booking — ground OR umpire. One document per booking.
**Document ID:** `{booking_id}` (Firestore auto-generated)

| Field Name | Data Type | Description |
| :--- | :--- | :--- |
| `kind` | String | `"ground"` \| `"umpire"` |
| `resource_id` | String | `ground_id` or `umpire_uid` |
| `resource_name` | String | Denormalized for display |
| `organizer_uid` | String | UID of organizer |
| `organizer_name` | String | Denormalized |
| `counterparty_uid` | String | `ground_owner_uid` or `umpire_uid` |
| `counterparty_name` | String | Denormalized |
| `date` | String | "2025-04-15" |
| `slot_start` | String | "07:00" |
| `slot_end` | String | "09:00" |
| `duration_minutes` | Number | e.g., `120` |
| `amount_paise` | Number | Always in paise |
| `platform_fee_paise` | Number | 5% of amount |
| `payout_amount_paise` | Number | amount_paise - platform_fee_paise |
| `payment_method` | String | `"razorpay"` \| `"cod"` |
| `payment_status` | String | `"pending"` \| `"authorized"` \| `"failed"` \| `"refunded"` |
| `razorpay_order_id` | String | (if razorpay) |
| `razorpay_payment_id` | String | (if razorpay + captured) |
| `status` | String | `"held"` \| `"pending_payment"` \| `"confirmed"` \| `"cancelled"` \| `"no_show"` \| `"completed"` |
| `qr_token` | String | Signed JWT for QR verification |
| `match_id` | String | Optional CricketHub match link |
| `notes` | String | Organizer's notes |
| `created_at` | Timestamp | |
| `updated_at` | Timestamp | |
| `confirmed_at` | Timestamp | |
| `cancelled_at` | Timestamp | |
| `cancellation_reason` | String | |
| `refund_amount_paise` | Number | Actual refunded amount |
| `refund_status` | String | `"none"` \| `"requested"` \| `"processed"` \| `"failed"` |
| `refund_id` | String | Razorpay refund ID |

### Sub-collection: `bookings/{booking_id}/audit/{logId}` (NEW)
**Purpose:** Immutable audit log. Each entry = `{ts, actor_uid, action, from_status, to_status, reason}`.
**Write authority:** Cloud Functions only.

---

## 9. Collection: `ground_reviews` (NEW)

**Document ID:** `{review_id}`

| Field Name | Data Type | Description |
| :--- | :--- | :--- |
| `ground_id` | String | FK to `grounds/{id}` |
| `booking_id` | String | FK to `bookings/{id}` (1:1 unique constraint) |
| `reviewer_uid` | String | UID of reviewer |
| `reviewer_name` | String | Denormalized |
| `rating` | Number | 1–5 |
| `text` | String | Optional review text (≤ 500 chars) |
| `created_at` | Timestamp | |

---

## 10. Collection: `umpires` (NEW)

**Document ID:** `{uid}` (same as user UID)

| Field Name | Data Type | Description |
| :--- | :--- | :--- |
| `user_uid` | String | FK to `users/{uid}` |
| `display_name` | String | Denormalized |
| `phone_number` | String | Encrypted via rules |
| `city` | String | Primary city |
| `experience_years` | Number | |
| `certifications` | Array of Map | `{name, document_url, verified}` |
| `day_rate` | Number | INR per match |
| `hourly_rate` | Number | INR per hour |
| `bio` | String | ≤ 500 chars |
| `photo_url` | String | |
| `verified` | Boolean | Admin flag |
| `avg_rating` | Number | Cached |
| `review_count` | Number | Cached |
| `matches_officiated` | Number | Cached |
| `status` | String | `"draft"` \| `"pending_verification"` \| `"active"` \| `"paused"` |
| `created_at` | Timestamp | |
| `updated_at` | Timestamp | |

### Sub-collection: `umpires/{uid}/availability/{date_iso}`
Same shape as `grounds/{id}/slots/{date}`.

---

## 11. Collection: `umpire_reviews` (NEW)

Same shape as `ground_reviews`.

---

## 12. Collection: `payout_ledger` (NEW)

**Document ID:** `{ownerUid}_{weekStartIso}` (e.g., `uid_abc_2025-W15`)

| Field Name | Data Type | Description |
| :--- | :--- | :--- |
| `owner_uid` | String | |
| `week_start` | String | "2025-04-07" (Monday ISO) |
| `week_end` | String | "2025-04-13" |
| `booking_count` | Number | |
| `gross_amount_paise` | Number | |
| `platform_fee_paise` | Number | |
| `net_payout_paise` | Number | gross - fee |
| `razorpay_settlement_id` | String | |
| `settlement_status` | String | `"pending"` \| `"settled"` \| `"failed"` |
| `bookings` | Array of String | Booking IDs in this payout week |
| `created_at` | Timestamp | |

---

## 13. Collection: `razorpay_events` (NEW)

**Document ID:** `{event_id}` (Razorpay's event_id)

| Field Name | Data Type | Description |
| :--- | :--- | :--- |
| `event_type` | String | e.g., `"payment.captured"` |
| `payload` | Map | Full payload |
| `processed` | Boolean | |
| `processed_at` | Timestamp | |
| `received_at` | Timestamp | |
| `signature_verified` | Boolean | |

**Rule:** Each event processed **at most once** (Firestore transaction checks `processed=false`).

---

## 14. Sub-collection: `users/{uid}/favorite_grounds/{groundId}` (NEW)

| Field Name | Data Type | Description |
| :--- | :--- | :--- |
| `ground_id` | String | |
| `saved_at` | Timestamp | |

---

## 15. Sub-collection: `users/{uid}/bookings/{bookingId}` (NEW)

Denormalized pointer to the user's bookings.

| Field Name | Data Type | Description |
| :--- | :--- | :--- |
| `booking_id` | String | FK |
| `kind` | String | |
| `resource_id` | String | |
| `resource_name` | String | |
| `status` | String | |
| `date` | String | |
| `slot_start` | String | |
| `slot_end` | String | |
| `amount_paise` | Number | |
| `saved_at` | Timestamp | |

Written by Cloud Function `onBookingConfirmed`.

---

## 16. User Profile Additions (Phase 3)

`users/{uid}` document gets new optional fields:

| Field Name | Data Type | Description |
| :--- | :--- | :--- |
| `role` (extended) | String | `"player"` \| `"organizer"` \| `"scorer"` \| `"ground_owner"` \| `"umpire"` |
| `payout_bank_ref` | String | Encrypted bank/UPI ref for payouts |
| `payout_method` | String | `"upi"` \| `"bank_account"` |
| `default_city` | String | Default search city |

---

## Composite Indexes Required (firestore.indexes.json — Phase 3 additions)

See `docs/firestore_indexes_phase3_addendum.json` for the full list.

---

## Denormalization Strategy (Phase 3)

To minimize read counts, denormalize on the `bookings` doc:
- `organizer_name` (avoid join to `users`)
- `counterparty_name` (avoid join to `grounds` or `umpires`)
- `resource_name` (avoid join)

Updates to source fields are mirrored by a Cloud Function (eventually consistent).

---

## Cost Estimate (Phase 3 — monthly, India region)

Assuming 5,000 active grounds + 500 active umpires + 20,000 bookings/month:

| Operation | Reads/mo | Writes/mo |
| :--- | :--- | :--- |
| Ground browse (100k page views) | 300,000 | 0 |
| Calendar open (50k page views) | 50,000 | 0 |
| Booking create (20k) | 60,000 | 40,000 |
| Webhook (20k events) | 20,000 | 20,000 |
| Total | ~430k | ~60k |

Well within Blaze plan free tier for small-medium scale.

---

*End of Phase 3 Schema Addendum.*