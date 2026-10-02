# App Flow Document — Phase 3 Addendum: CricketHub

> **Scope:** Extends `CricketHub_AppFlow.md` (v1.0) with Phase 3 user journeys — Ground Marketplace, Umpire Marketplace, Razorpay Checkout, Owner Panel.

## Document Info
| Attribute | Details |
| :--- | :--- |
| **Project Name** | CricketHub |
| **Document Version** | 3.0.0 (Phase 3 Addendum) |
| **Date** | October 2, 2026 |

---

## Guide to Reading this Document

- `[Screen Name]` — distinct UI screen or bottom-sheet.
- `{Action}` — user interaction (button tap, form submit).
- `<Decision / Condition>` — system check or user choice.
- `->` — navigation.

---

## New Global Navigation

Standard user gains a new "Marketplace" section in Menu.
Ground Owner / Umpire roles get dedicated dashboards.

**Standard user:** Home · My Cricket · Tournaments · Marketplace · Menu
**Ground Owner:** Owner Home · Calendar · Earnings · Menu
**Umpire:** Umpire Home · Availability · Earnings · Menu

---

## Flow 7: Ground Browse → Book → Pay → Confirm (Organizer / Player)

1. **[Home / Marketplace Tab]** → {Tap "Find a Ground"} → **[Ground Listing Screen]**
2. **[Ground Listing]** — Default view: grounds in user's `default_city`, sorted by rating.
   - {Tap Filter Chip} → Query updates → New results.
   - {Tap Sort} → Dropdown: Distance / Price / Rating.
3. {Tap a `GroundCard`} → **[Ground Details]**
4. **[Ground Details]** — Default tab: Overview.
   - {Tap "Calendar" tab} → **[Ground Calendar]**
5. **[Ground Calendar]** — Month view; tap date → slots load.
   - Available slot (green) → `[Book Slot]` CTA enabled.
   - Booked (grey) / Blocked (striped) → non-tappable.
   - Held (orange) → "Resume checkout" CTA.
   - {Tap available slot + Continue} → **[Checkout Screen]**
6. **[Checkout Screen]** — Order summary; payment method radio.
   - {Tap "Pay & Book"} → Cloud Function `createRazorpayOrder` → **[Razorpay SDK Sheet]**
7. **[Razorpay SDK Sheet]** (system overlay)
   - Payment success → Flutter receives `{payment_id, order_id, signature}` → POST to `verifyRazorpayPayment` → **[Booking Success Screen]**
   - Payment failed → return to Checkout, slot auto-releases after 10 min.
8. **[Booking Success Screen]** — Big QR code, booking_id, ground address, action row.
   - FCM also sent to ground owner: "New booking on {date}".

---

## Flow 8: Ground Owner Onboarding & Listing

1. **[Menu Screen]** → {Tap "Become a Ground Owner"} → **[Owner Onboarding]**
2. **[Owner Onboarding]** — Intro card; bank/UPI input; ID upload.
   - {Tap "Submit for verification"} → admin notification
3. <Admin reviews docs> → <Sets `verified=true`> → FCM: "You're verified!"
4. **[Owner Dashboard]** → {Tap "Add Ground"} → **[Create Ground Wizard]** (4 steps)
   - **Step 1:** Basics (name, address, lat/lng).
   - **Step 2:** Pitch & Photos.
   - **Step 3:** Pricing & hours.
   - **Step 4:** Review & Submit.
5. **[Owner Dashboard]** → "Calendar" tab — Month view; per-slot toggles.
6. **[Owner Dashboard]** → "Earnings" tab — Week picker + payout summary.

---

## Flow 9: Umpire Onboarding & Booking

1. **Umpire Onboarding** (analogous to Flow 8) — Certification docs required.
3. **Umpire Dashboard** → Incoming `bookings` where `counterparty_uid==self`.
   - {Tap pending booking} → Accept or Decline.
   - Accept → booking.status → 'confirmed'.
   - Decline → booking.status → 'cancelled', organizer notified.
4. **Organizer finds umpires** (analogous to ground search).
   - Marketplace → Umpire Listing → Umpire Profile → Request → Razorpay/COD → Success.

---

## Flow 10: Cancellation & Refund

1. **[Booking Detail Screen]** → {Tap "Cancel Booking"} → **[Cancel Modal]**
2. **[Cancel Modal]** — Cancellation policy breakdown based on time-to-slot.
   - "Full refund" if ≥ 24h
   - "50% refund" if 12–24h
   - "No refund" if < 12h
   - {Select reason} → {Tap "Confirm Cancellation"} → Cloud Function `onBookingCancelled`.
3. <Cloud Function issues Razorpay refund> → booking → 'cancelled', `refund_status='processed'`.
4. FCM push to organizer: "Refund of ₹{amount} initiated".

---

## Flow 11: Check-in & QR Verification (Ground Owner)

1. Organizer arrives at ground with QR code on phone.
2. Owner opens Owner Dashboard → {Tap "Scan QR"} → **[QR Scanner Screen]**
3. **[QR Scanner]** → Mobile scanner reads JWT → verifies booking → displays `[Match Ready!]`.
4. If QR is invalid/expired: `[Invalid QR][Try Again]`.

---

## Flow 12: Post-Match Review

1. Within 7 days of slot end: FCM push "Rate your ground & umpire".
2. **[Rating Prompt]** — 5-star + optional text → {Tap "Done"} → Save review.

---

*End of Phase 3 App Flow Addendum.*