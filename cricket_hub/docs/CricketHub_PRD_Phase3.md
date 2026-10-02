# Product Requirements Document (PRD) — Phase 3 Addendum: CricketHub

> **Scope:** This document extends `CricketHub_PRD.md` (v1.0) with the **Phase 3 Marketplace & Bookings** module — Grounds, Umpires, Slot Booking, and Razorpay Payments. Phase 1 (Auth/Teams/Matches/Offline Scoring) and Phase 2 (Tournaments/NRR/Stats/Push) remain unchanged but are referenced where relevant.

## Document Info
| Attribute | Details |
| :--- | :--- |
| **Project Name** | CricketHub |
| **Document Version** | 3.0.0 (Phase 3 Addendum) |
| **Authors** | Smeet Jariwala, Aman Sinha |
| **Date** | October 2, 2026 |
| **Status** | Approved for Development |
| **Phase** | 3 of 4 |
| **Target Platforms** | iOS, Android (Flutter) |

---

## Phase 3 Executive Summary

Phase 3 transforms CricketHub from a scoring app into a **two-sided marketplace** that closes the loop on match-day logistics. Players and organizers who already score matches through CricketHub will be able to:

1. Browse and book cricket grounds by city, pitch type, amenities, and price.
2. Browse and book certified umpires by experience, city, and day rate.
3. Pay the booking advance online (Razorpay) or confirm cash-on-ground bookings.
5. Manage ground inventory from a dedicated owner panel (block dates, set prices, upload photos).

By owning the entire match-day transaction, CricketHub unlocks the **transaction-based GMV** business goal ($10K+ monthly by end of Phase 3) and gives the local cricket ecosystem a single, trustworthy platform.

---

## Updated Goals & Objectives (Phase 3)

### Business Goals (additions)
1. **Marketplace Liquidity:** Onboard 150 grounds and 80 umpires across 5 Indian cities (Ahmedabad, Mumbai, Bengaluru, Hyderabad, Pune) within 6 months.
2. **GMV Target:** $10,000+ in monthly Gross Merchandise Value via ground + umpire bookings.
3. **Take Rate:** 5% platform fee on every confirmed online booking.
4. **Repeat Use:** ≥ 35% of organizers return to book a second match within 60 days.

### User Goals (additions)
1. As a Player/Organizer, find an available pitch within 2 km of home and book a slot in under 90 seconds.
2. As an Umpire, get discovered by organizers in the city and accept/decline booking requests from the app.
3. As a Ground Owner, list a ground in under 5 minutes and see a calendar of confirmed bookings.
4. As an Organizer, pay securely online (UPI / Card / NetBanking) and receive a QR-coded booking confirmation.

---

## Non-Goals (Phase 3 Out of Scope)

*   Real-time dispute resolution beyond the Razorpay refund API.
*   Multi-day ground rentals.
*   Equipment rental (bats, balls, stumps).
*   Sponsorship or advertising slots inside ground listings.
*   Subscription tiers for players (Premium stats remain Phase 4).

---

## Success Metrics / KPIs (Phase 3)

| Metric | Target | Measurement |
| :--- | :--- | :--- |
| Ground Listing Fill Rate | ≥ 80% have ≥ 1 photo, ≥ 3 amenities, ≥ 1 price tier | Daily Firestore audit |
| Booking Conversion | ≥ 12% of ground detail viewers complete a slot reservation | Analytics event |
| Payment Success Rate | ≥ 95% of Razorpay orders complete successfully | Razorpay dashboard |
| Umpire Match-Date Reliability | ≥ 95% of accepted bookings result in a confirmed umpire | Umpire confirmation |
| Owner Dashboard Adoption | ≥ 60% of listed grounds log in once per week | Auth logs |
| Refund Time | Median refund ≤ 5 business days | Admin queue |

---

## New Personas — Phase 3

### 5. Raju (The Ground Owner)
- **Demographics:** 42, owns a 5-ground turf facility on the outskirts of Ahmedabad.
- **Goals:** Fill weekday slots; advertise weekend tournaments; reduce phone-call bookings.
- **Pain Points:** Phone calls at odd hours; no-shows; manual cash collection.
- **Tech Savviness:** Moderate — uses WhatsApp and Google Pay; needs a frictionless app onboarding.

### 6. Iqbal (The Local Umpire)
- **Demographics:** 38, ex-club cricketer, certified by state association.
- **Goals:** Supplement income by umpiring 2–3 matches per weekend.
- **Pain Points:** Word-of-mouth booking only; no-show organizers who forget to pay.

---

## User Stories — Phase 3

| ID | Persona | User Story | Acceptance Criteria | Priority | Phase |
| :--- | :--- | :--- | :--- | :--- | :--- |
| US-11 | Ground Owner | Register ground with name, address, photos, amenities | Form submission creates `grounds/{id}` with `verified=false` until admin review | Must Have | 3 |
| US-12 | Ground Owner | Set per-slot prices and block unavailable dates | Calendar tab → block toggle → `ground_blocked_slots` updated | Must Have | 3 |
| US-13 | Organizer | Search grounds in my city with filters | Search screen queries `grounds` with city/pitch/price filters | Must Have | 3 |
| US-14 | Organizer | Select date and time slot on calendar and proceed to checkout | Calendar shows available/booked/blocked slots; 10-minute hold during checkout | Must Have | 3 |
| US-15 | Organizer | Pay via UPI/Card/NetBanking | Razorpay SDK with order_id; success → `booking.status='confirmed'`, owner notified | Must Have | 3 |
| US-16 | Organizer | QR-coded booking confirmation | Confirmation screen displays QR containing `booking_id + signature` | Must Have | 3 |
| US-17 | Ground Owner | See upcoming bookings and mark "Player arrived" | Owner dashboard list with timestamp; aggregates into weekly revenue | Must Have | 3 |
| US-18 | Umpire | Register umpire profile with certification and day-rate | `umpires/{uid}` doc with `certifications` array, `rate_card` | Must Have | 3 |
| US-19 | Organizer | Book umpire alongside ground | Umpire search → profile → request → Razorpay or COD → push notification | Must Have | 3 |
| US-20 | Player | Rate a ground and umpire after a match | Post-match 5-star prompt + text review | Should Have | 3 |
| US-21 | Umpire | Accept/decline booking requests | Push → accept/decline → status updated; organizer notified | Must Have | 3 |
| US-22 | Organizer | Cancel booking and receive refund per policy | Cancel → policy check (full >24h, 50% 12–24h, 0% <12h) → Razorpay refund | Must Have | 3 |
| US-23 | Ground Owner | Weekly payout summary | Owner dashboard tab shows last 7 days: bookings count, gross, fee, net | Should Have | 3 |

---

## Functional Requirements

### Module 8: Ground Listings (Owner Panel)
- **FR-GROUND-01 (High):** Authenticated user can register as Ground Owner by submitting form (name, address, pitch type, amenities, photos, pricing).
- **FR-GROUND-02 (High):** Upload up to 10 photos and a primary `cover_photo_url`.
- **FR-GROUND-03 (High):** Per-slot pricing: weekday hourly, weekend hourly, full-day. Currency INR.
- **FR-GROUND-04 (High):** Block specific dates or recurring weekday rules.
- **FR-GROUND-05 (Medium):** Admin verification badge; verified grounds rank higher in search.
- **FR-GROUND-06 (High):** Owner dashboard shows upcoming bookings, weekly revenue, occupancy %, ratings.

### Module 9: Ground Discovery (Player/Organizer)
- **FR-DISC-01 (High):** Search with filters: city, pitch type, price range, amenities, rating ≥ X.
- **FR-DISC-02 (High):** Sort by distance (location permission), price, most booked.
- **FR-DISC-03 (High):** Detail page: photo carousel, address map link, amenities grid, pricing, calendar, reviews, "Book" CTA.
- **FR-DISC-04 (Medium):** "Save"/"Favorite" a ground.
- **FR-DISC-05 (Medium):** "Similar grounds" carousel.

### Module 10: Slot Booking & Reservation
- **FR-BOOK-01 (High):** Slot = date + start time + duration. Default duration 2 hours; configurable per ground.
- **FR-BOOK-02 (High):** Slot states: `available`, `held` (10-min reservation lock), `booked`, `blocked`, `in_match`.
- **FR-BOOK-03 (High):** Cloud Function enforces no double-booking via Firestore transaction on `ground_slots/{groundId}/{date}`.
- **FR-BOOK-04 (High):** Successful booking creates unique `booking_id` and QR code (signed JWT).
- **FR-BOOK-05 (High):** Organizer can cancel; refund policy applies.
- **FR-BOOK-06 (High):** Refund schedule:
    - **≥ 24 hours** before slot start: **100% refund**
    - **12–24 hours** before: **50% refund**
    - **< 12 hours** before: **No refund**
    - **No-show:** **No refund**, owner receives 100%.

### Module 11: Razorpay Payment Integration
- **FR-PAY-01 (High):** Flutter opens Razorpay SDK for UPI, Cards, NetBanking, Wallets.
- **FR-PAY-02 (High):** Cloud Function `createRazorpayOrder` creates Razorpay order with amount (paise) and `booking_id` in notes.
- **FR-PAY-03 (Critical):** Flutter receives `payment_id`, `order_id`, `signature` and POSTs to `verifyRazorpayPayment` Cloud Function.
- **FR-PAY-04 (Critical):** Server verifies HMAC-SHA256 signature using `RAZORPAY_KEY_SECRET`. Rejects others with HTTP 400.
- **FR-PAY-05 (High):** On success, booking → `confirmed`, slot → `booked`, both organizer and owner receive FCM.
- **FR-PAY-06 (High):** Webhook `/razorpayWebhook` handles `payment.captured`, `payment.failed`, `refund.processed` via Admin SDK, bypassing rules. Idempotent.
- **FR-PAY-07 (Medium):** Platform fee = 5% of booking amount, deducted from owner payout ledger.
- **FR-PAY-08 (Medium):** Cash-on-Ground alternative: booking `pending_payment_cod`, slot held.

### Module 12: Umpire Marketplace
- **FR-UMP-01 (High):** Authenticated user can register as umpire submitting name, city, certification document, experience, day rate.
- **FR-UMP-02 (High):** Admin verifies umpire. Verified umpires get a badge.
- **FR-UMP-03 (High):** Profile shows past matches, rating, reviews.
- **FR-UMP-04 (High):** Umpires manage a weekly availability calendar.
- **FR-UMP-05 (High):** Organizer searches umpires by city, certification level, price.
- **FR-UMP-06 (High):** Booking flow mirrors ground booking; Razorpay or COD.
- **FR-UMP-07 (Medium):** Aggregated ratings on profile; minimum 5 reviews before search listing.

### Module 13: Reviews & Ratings
- **FR-REV-01 (Medium):** Post-booking screen (within 7 days) prompts user to rate ground/umpire (1–5 stars + optional text).
- **FR-REV-02 (Medium):** One review per booking enforced by Firestore rules.
- **FR-REV-03 (Medium):** Aggregate `avg_rating` and `review_count` stored on ground/umpire doc.

---

## Screen-by-Screen Breakdown

### 8. Ground Marketplace Screens
1. **Ground Listing** — Filters bar (city, pitch, price, amenities), vertical list of GroundCard, map view toggle.
2. **Ground Details** — Hero carousel, Overview/Calendar/Reviews/Location tabs, sticky bottom "Book this ground" CTA.
3. **Calendar / Slot Picker** — Month-view calendar, slot chips (green/orange/grey), bottom sheet slot confirmation.
4. **Checkout** — Order summary, payment method radio (online/COD), "Pay & Book" CTA.
5. **Booking Success** — QR code, booking details, action buttons (calendar/directions/share).
6. **Ground Owner Panel** — Bottom-tab sub-shell: Dashboard / Calendar / Listings / Earnings.

### 9. Umpire Marketplace Screens
1. **Umpire Listing** — Same pattern as Ground Listing.
2. **Umpire Profile** — Avatar hero, certification badges, reviews tab.
3. **Umpire Booking Request** — Organizer sends → Umpire push → Accept/Decline.
4. **Umpire Dashboard** — Upcoming bookings, availability toggle, weekly earnings.

---

## Updated Non-Functional Requirements

1. **Payment Security:** All Razorpay integration uses server-side signature verification; Flutter never holds `RAZORPAY_KEY_SECRET`.
2. **Double-Booking Prevention:** Slot reservation uses Firestore transactions; race conditions across users are impossible.
3. **Booking Hold Expiry:** Unpaid holds auto-expire via scheduled Cloud Function (every 5 minutes).
4. **PII Protection:** Umpire phone numbers, ground owner bank details never exposed publicly via Firestore rules.
5. **Payment Latency:** Razorpay order creation ≤ 1s; webhook → status update ≤ 3s.
6. **Offline Behavior:** Marketplace screens show last-cached data when offline; booking creates require connectivity.
7. **Audit Trail:** Every booking status change logged in `booking_audit_log/{logId}`.

---

## Updated Technical Considerations

### New Firestore Collections (Phase 3)
- `/grounds/{groundId}` — Ground master record.
- `/grounds/{groundId}/slots/{date}` — Per-day slot inventory.
- `/ground_blocked_rules/{ruleId}` — Recurring owner-block rules.
- `/bookings/{bookingId}` — Booking record (ground or umpire).
- `/booking_audit_log/{logId}` — Immutable audit log (admin-write only).
- `/umpires/{uid}` — Umpire master record.
- `/umpires/{uid}/availability/{date}` — Umpire per-day slot inventory.
- `/ground_reviews/{reviewId}` and `/umpire_reviews/{reviewId}`.
- `/users/{uid}/favorite_grounds/{groundId}` — Saved grounds.
- `/payout_ledger/{groundOwnerUid}/{weekStartIso}` — Weekly owner payout summary.

### New Cloud Functions (Phase 3)
- `createRazorpayOrder` (`onCall`) — Creates Razorpay order.
- `verifyRazorpayPayment` (`onCall`) — Verifies signature, updates booking.
- `razorpayWebhook` (`onRequest`) — Receives webhooks (signature-verified, idempotent).
- `expireStaleHolds` (`onSchedule`, every 5 min) — Releases unpaid holds.
- `onBookingConfirmed` (`onDocumentUpdated`) — FCM to owner + organizer.
- `onBookingCancelled` (`onCall`) — Refund per policy.
- `aggregateGroundRating` (`onDocumentCreated` on review) — Recomputes aggregate.
- `weeklyPayoutDigest` (`onSchedule`, Monday 09:00 IST) — Payout summary.

### New Flutter Dependencies (Phase 3)
- `razorpay_flutter: ^1.3.7`
- `qr_flutter: ^4.1.0`
- `mobile_scanner: ^5.2.3`
- `cached_network_image: ^3.4.1`
- `table_calendar: ^3.1.2`

---

## Release Plan (Phase 3)

| Sub-Phase | Duration | Deliverable |
| :--- | :--- | :--- |
| 3a — Ground Browse + Discovery | Weeks 1–3 | Ground listing, detail page, search/filter |
| 3b — Ground Booking + Razorpay | Weeks 4–7 | Calendar, slot picker, checkout, payment, QR |
| 3c — Ground Owner Panel | Weeks 5–8 | Create ground, manage slots, earnings |
| 3d — Umpire Marketplace | Weeks 7–12 | Umpire profile, search, request, accept/decline |
| 3e — Reviews, Ratings, Polish | Weeks 10–12 | Reviews, ratings, refund flow, UAT |

Total Phase 3 timeline: 12 weeks (Months 7–9 per the parent PRD).

---

## Risks & Mitigations (Phase 3 additions)

| Risk | Impact | Mitigation |
| :--- | :--- | :--- |
| Double-booking under high concurrency | High | Firestore transaction with optimistic slot lock |
| Razorpay webhook spoofing | Critical | Server-side HMAC-SHA256 signature verification |
| Ground owner fraud | Medium | Admin verification flow + Govt ID + ownership proof |
| Umpire no-shows | High | Umpire check-in by organizer; no-show flag with penalty |
| Razorpay API outage | High | Auto-retry + cash-on-Ground mode |
| Refund disputes | Medium | Transparent cancellation policy shown before payment |
| PII leakage | Critical | Firestore rules + signed URLs for sensitive docs |

---

## Glossary (Phase 3 additions)

- **GMV** — Gross Merchandise Value; total transaction volume.
- **Slot** — Bookable time interval (e.g., 7:00–9:00 AM) on a date at a ground.
- **Hold** — Temporary lock on a slot during checkout (auto-releases after 10 min if unpaid).
- **Platform Fee** — 5% retained by CricketHub on each successful online booking.
- **Umpire Certification** — Document proving state/national-level qualification.
- **COD** — Cash on Ground; payment at venue.
- **Webhook Signature** — Razorpay's HMAC-SHA256 signature verifying webhook authenticity.
- **Razorpay Order** — Pre-payment record created via Razorpay REST API.

---

*End of Phase 3 Addendum. Phase 1/2 contracts in the base PRD remain authoritative.*