# UI/UX Guidelines & Wireframe Specifications — Phase 3 Addendum: CricketHub

> **Scope:** Extends `CricketHub_UI_UX_Guidelines.md` (v2.0, light mode) for Marketplace screens.

## Document Info
| Attribute | Details |
| :--- | :--- |
| **Project Name** | CricketHub |
| **Document Version** | 3.0.0 (Phase 3 Addendum) |
| **Date** | October 2, 2026 |
| **Theme** | Light Mode (matches Phase 2 redesign) |

---

## Phase 3 UX Principles

1. **Trust signals are critical:** Verified badges, review counts, total bookings shown prominently.
2. **One-tap action for return users:** Returning organizers see "Your last booking" on home.
3. **Booking urgency without anxiety:** Slot availability color-coding avoids panic-buying.
4. **Owner workflows are admin-grade:** Owners need dense data views.

---

## Phase 3 Color Tokens

| Token | Hex | Use |
| :--- | :--- | :--- |
| `slotAvailable` | `#10B981` | Calendar slot = available |
| `slotBooked` | `#9CA3AF` | Calendar slot = booked |
| `slotHeld` | `#F97316` | Calendar slot = held by user |
| `slotBlocked` | `border` stripes | Owner-blocked slot |
| `verifiedBadge` | `#0EA5E9` | Verified ground/umpire badge |
| `qrCodeBg` | `#FFFFFF` | QR codes (max contrast) |

---

## Screen Specs

### Ground Listing
- Sticky search bar + filter chips row.
- Vertical scrollable `ListView` of `GroundCard` (photo, name, city, ₹X/hr, ★ rating, [Book]).
- Empty state: "No grounds in this city yet."

### Ground Details
- Hero photo carousel (220px tall).
- Title section: name, city, ★ rating.
- TabBar: Overview | Calendar | Reviews | Location.
- Sticky bottom bar: Price summary + "Book this ground" CTA.

### Ground Calendar / Slot Picker
- Month-view calendar.
- Slot grid for selected date:
  - `07:00 - 09:00` (green, available)
  - `09:00 - 11:00` (orange, held)
  - `11:00 - 13:00` (grey, booked)
  - `13:00 - 15:00` (striped, blocked)
- Selected slot has primary-color border.
- Sticky bottom: "Continue with 07:00 - 09:00 slot" CTA.

### Booking Checkout
- Order Summary card: ground, date, time, hours.
- Price Breakdown card: Subtotal, Platform fee (5%), Total.
- Payment method radio: Online (UPI / Card / NetBanking) | Cash on Ground.
- Notes field.
- Primary CTA: "Pay & Book".
- Below CTA: cancellation policy link.

### Booking Success
- Big success illustration (green checkmark).
- "Booking Confirmed" headline.
- QR Code card (240×240 white background).
- Booking details card: ground, time, total, status.
- Action buttons: Add to Calendar | Get Directions | Share Receipt.
- Tertiary: "View My Bookings".

### Ground Owner Dashboard
- Bottom nav: Dashboard | Calendar | Listings | Earnings.
- **Dashboard:** Today's bookings + Week revenue chart + Pending check-ins.
- **Calendar:** Month view with [Block Date] button.
- **Listings:** Owner's grounds + [+ Add Ground] FAB.
- **Earnings:** Week picker + payout table + chart.

### Create Ground Wizard (4 steps)
- **Step 1:** Name, Address, Lat/Lng.
- **Step 2:** Pitch type, Amenities, Photos grid.
- **Step 3:** Pricing, Open/Close, Slot duration.
- **Step 4:** Review → [Publish].

### Umpire Listing / Profile
- Same pattern as Ground Listing/Profile with certification badges instead of pitch type.

### Booking Detail
- Same as Booking Success + Cancel button → modal showing refund policy.

### QR Scanner
- Full-screen camera with overlay rectangle (QR target zone).
- After scan: bottom sheet with booking summary + "Mark Arrived" button.

---

## Micro-Interactions (Phase 3)

| Action | Effect |
| :--- | :--- |
| Hold a slot | Subtle haptic + slot chip animates orange |
| Payment success | Confetti burst from CTA + haptic |
| QR displayed | Fade-in with shimmer effect |
| Slot taken while checkout | Toast: "Sorry, this slot was booked by someone else." |

---

## Empty / Error States

| Screen | Empty | Error |
| :--- | :--- | :--- |
| Ground Listing | Empty pitch illustration, "No grounds match your filters" | "Couldn't load grounds. Pull to refresh." |
| Calendar | "Slots open soon" | "Couldn't load availability." |
| Booking Success | n/a | "QR not generated. We saved your booking." |
| Owner Dashboard | "No bookings yet" | "Couldn't load dashboard." |
| Umpire Dashboard | "No incoming requests" | "Couldn't load requests." |

---

*End of Phase 3 UI/UX Addendum.*