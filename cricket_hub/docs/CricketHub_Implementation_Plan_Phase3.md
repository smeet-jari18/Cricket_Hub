# Implementation Plan & Sprint Roadmap — Phase 3: CricketHub

> **Scope:** Phase 3 breakdown — Ground Marketplace, Umpire Marketplace, Razorpay Payments, Owner Panel.

## Document Info
| Attribute | Details |
| :--- | :--- |
| **Project Name** | CricketHub |
| **Document Version** | 3.0.0 (Phase 3 Addendum) |
| **Date** | October 2, 2026 |
| **Methodology** | Agile (2-Week Sprints) |
| **Phase** | 3 of 4 |
| **Duration** | 12 weeks (Months 7–9) |

---

## 1. Team Setup

Continuing from Phase 2 (1 Lead Flutter, 1 Mid Flutter, 1 Backend/Firebase, 1 PM, 1 Designer, 1 QA):
- Add 1 Backend Engineer focused on Razorpay integration + payment lifecycle testing.
- Designer ramp-down after 3 weeks.

Total Phase 3 team: 6.

---

## 2. Sprint Breakdown

### Sprint 6: Ground Listings Schema + Discovery
- Frontend: `ground_model.dart`, `ground_service.dart`, `ground_list_screen.dart`, `ground_detail_screen.dart`, `ground_filter_sheet.dart`.
- Backend: Define `grounds/{id}` collection schema + indexes. Deploy updated `firestore.rules`. Seed script.

### Sprint 7: Calendar + Slot Picker + Booking Flow
- Frontend: `ground_calendar_screen.dart`, `booking_checkout_screen.dart`, `booking_service.dart`, `booking_model.dart`.
- Backend: `createBookingHold`, `expireStaleHolds`.

### Sprint 8: Razorpay Integration + Payment Verification
- Frontend: `payment_service.dart`, `booking_success_screen.dart`, QR display.
- Backend: `createRazorpayOrder`, `verifyRazorpayPayment`, `razorpayWebhook`, `onBookingConfirmed`.

### Sprint 9: Ground Owner Panel
- Frontend: `owner_dashboard.dart`, `owner_create_ground_screen.dart`, `owner_calendar_screen.dart`, `owner_earnings_screen.dart`, `owner_qr_scanner_screen.dart`.
- Backend: `validateBookingQR`, image resize, storage rules.

### Sprint 10: Umpire Marketplace
- Frontend: `umpire_model.dart`, `umpire_service.dart`, `umpire_list_screen.dart`, `umpire_detail_screen.dart`, `umpire_dashboard.dart`, `umpire_availability_screen.dart`, `umpire_onboarding_screen.dart`.
- Backend: Define `umpires` collection. Update rules for umpire RBAC.

### Sprint 11: Reviews, Ratings, Cancellation, Polish
- Frontend: `booking_detail_screen.dart`, `leave_review_screen.dart`, `rating_stars.dart`.
- Backend: `onBookingCancelled`, `aggregateGroundRating`, `weeklyPayoutDigest`.

### Sprint 12: QA, Hardening & App Store Submission
- **Concurrent booking stress test** — script 50 simultaneous attempts on the same slot.
- **Razorpay live mode UAT** — book a real match in 1 city.
- Refund edge cases (24h/12h/0h boundary).
- iOS / Android TestFlight + Closed Testing track rollout.

---

## 3. Testing Strategy (Phase 3)

### Unit Tests (Cloud Functions)
- Slot reservation — 100% coverage on edge cases.
- Refund policy — 100% coverage on time-to-slot buckets.
- JWT QR verify — round-trip + tamper rejection.
- Razorpay signature — tamper rejection.
- Flutter: `booking_model_test.dart`, `ground_model_test.dart`.

### Integration Tests
- `integration_test/ground_booking_e2e.dart` — full booking → payment → success.
- `integration_test/owner_create_ground.dart` — wizard → publish.

### Manual UAT
- Beta program: 10 ground owners in Ahmedabad + 5 umpires, 30-day trial.

---

## 4. Deployment Strategy

### Feature flags
- `marketplace_live_enabled` — global on/off
- `marketplace_razorpay_live` — switch test to live keys
- `marketplace_ground_owners` — whitelist of UIDs

### Environments
- `crickethub-dev` — Phase 3 dev, Razorpay test mode.
- `crickethub-staging` — Phase 3 staging, Razorpay test mode.
- `crickethub-prod` — Phase 3 prod, Razorpay live mode, soft-launched in Ahmedabad.

---

## 5. Go-Live Plan

**Week 12 Soft Launch — Ahmedabad Only:**
1. Enable `marketplace_live_enabled` in `crickethub-prod` with city filter = 'Ahmedabad'.
2. Manually onboard 10 ground owners via direct outreach.
3. Monitor Razorpay transactions + Firestore errors for 7 days.
4. Expand to Mumbai → Bengaluru → Hyderabad → Pune (one city/week).

---

## 6. Phase 3 Budget & Resources

| Resource | Quantity | Notes |
| :--- | :--- | :--- |
| Flutter Dev (Lead) | 1 | Full 12 weeks |
| Flutter Dev (Mid) | 1 | Full 12 weeks |
| Backend Engineer | 2 | 12 weeks; 1 from existing |
| Designer | 0.5 | First 3 weeks |
| QA | 1 | Full 12 weeks |
| PM | 0.5 | Full 12 weeks |

External costs:
- Razorpay fees: 2% per transaction (passed through to user as "platform fee")
- Firebase: estimated $200–$500/mo at MVP scale
- Beta ground owner incentives: ~₹50,000

---

## 7. Risks & Mitigations

| Risk | Mitigation |
| :--- | :--- |
| Razorpay API instability in test mode | Use Razorpay's UAT API; fallback to mock payment |
| Concurrent booking bugs | Stress test in Sprint 12; UI race conditions need careful design |
| Ground owner onboarding drop-off | 4-step wizard with autosave; FCM follow-ups |
| Umpire verification bottleneck | Build admin web panel (Phase 4); manually process for now |
| Cost overrun on Cloud Storage | Lifecycle rules: delete orphan photos after 30 days |

---

*End of Phase 3 Implementation Plan Addendum.*