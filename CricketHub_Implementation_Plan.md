# Implementation Plan & Sprint Roadmap: CricketHub

## Document Info
| Attribute | Details |
| :--- | :--- |
| **Project Name** | CricketHub |
| **Document Version** | 1.0.0 |
| **Author** | Smeet Jariwala , Aman Sinha |
| **Methodology** | Agile (2-Week Sprints) |
| **Date** | September 21, 2026 |

---

## 1. Development Team Setup

To execute Phase 1 (MVP) within a 10 to 12-week timeframe, the following team structure is recommended:
* **1x Technical Project Manager (Scrum Master)**
* **1x UI/UX Designer** (Part-time / Front-loaded)
* **2x Flutter Developers** (1 Lead, 1 Mid-level)
* **1x Backend/Firebase Developer** (Focus on Cloud Functions, Security Rules, Schema)
* **1x QA Tester** (Manual testing, heavy focus on the scoring engine)

---

## 2. Environment & Infrastructure Setup (Sprint 0)

Before any product code is written, the foundation must be established.
* **Duration:** 1 Week
* **Deliverables:**
  * **Source Control:** Set up GitHub repository with branch protection rules (`main`, `staging`, `develop`).
  * **Firebase Projects:** Create 3 separate Firebase environments: `crickethub-dev`, `crickethub-staging`, and `crickethub-prod`.
  * **Flutter Flavors:** Configure Flutter app to support Dev, Staging, and Prod builds.
  * **CI/CD:** Set up GitHub Actions to run `flutter analyze` and `flutter test` on Pull Requests.
  * **Base Architecture:** Integrate Riverpod (State Management), GoRouter (Routing), and Isar (Local DB).

---

## 3. Phase 1 (MVP) Sprint Breakdown

Phase 1 focuses exclusively on User Auth, Team/Match Creation, Offline Scoring, and Live Score Viewing.

### Sprint 1: Authentication & User Profiles
* **Duration:** 2 Weeks
* **Frontend Tasks:**
  * Build Splash screen and Onboarding UI.
  * Implement Phone Number (OTP) input and Google Sign-In UI.
  * Build Profile Setup UI (Name, Avatar, Player Role).
  * Build Main Bottom Navigation shell.
* **Backend Tasks:**
  * Enable Firebase Auth (Phone + Google).
  * Set up Firestore `users` collection and basic Security Rules.
  * Configure Firebase App Check (reCAPTCHA/App Attest).

### Sprint 2: Teams & Pre-Match Setup
* **Duration:** 2 Weeks
* **Frontend Tasks:**
  * Build "My Cricket" tab and "Create Team" forms.
  * Implement "Add Player" functionality (Search by phone).
  * Build "Start Match" flow (Select Teams, Overs, Assign Scorer).
  * Build the "Toss" and "Select Openers" UI.
* **Backend Tasks:**
  * Define `teams` and `matches` schema in Firestore.
  * Set up Cloud Storage buckets for team logos.
  * Write Security Rules allowing only team admins to edit rosters.

### Sprint 3: The Scoring Engine (Core Offline Functionality)
* **Duration:** 2 Weeks (High Complexity)
* **Frontend Tasks:**
  * Build the Scoring Dashboard UI (Score header, big action buttons).
  * Implement Local State Engine (Riverpod): Track runs, wickets, extras, strike rotation, and over completion.
  * Integrate Isar local database: Save every ball locally *first* to ensure zero-lag offline performance.
  * Implement "Undo" functionality (rolling back the local state).
* **Backend Tasks:**
  * Define the `balls` sub-collection schema.

### Sprint 4: Cloud Sync & Live Fan Viewing
* **Duration:** 2 Weeks
* **Frontend Tasks:**
  * Build Network Connectivity listener.
  * Build Cloud Sync background worker: Push Isar queued balls to Firestore via `WriteBatch`.
  * Build "Live Match Center" UI (Summary, Full Scorecard, Text Commentary).
  * Implement real-time Firestore Snapshot listeners for the Live Viewer.
* **Backend Tasks:**
  * Write strict Security Rules for the `matches` collection (Only `scorer_uid` can write).
  * Set up `onMatchComplete` Cloud Function to aggregate basic player stats.

### Sprint 5: QA, Polish & App Store Submission
* **Duration:** 2 Weeks
* **Tasks:**
  * **UAT (User Acceptance Testing):** Conduct a simulated live match at a local park. Test scoring in airplane mode.
  * Bug fixing and UI polish.
  * Generate App Icons, Splash Screens, and Store Screenshots.
  * Submit iOS app to Apple TestFlight / App Store Connect.
  * Submit Android app to Google Play Console (Closed Testing track).

---

## 4. Phase 2, 3, & 4 Roadmap (High-Level)

### Phase 2: Tournaments & Advanced Stats (Months 4-6)
* **Key Features:** Round-robin/Knockout logic, auto-calculating Points Tables (with NRR), advanced career stats aggregation, Push Notifications (Wickets/Match Start).
* **Tech Focus:** Firebase Cloud Messaging (FCM) integration, Complex Node.js Cloud Functions for NRR algorithms.

### Phase 3: Marketplace & Bookings (Months 7-9)
* **Key Features:** Ground Owner dashboard, Umpire listings, Availability Calendars, Checkout Flow.
* **Tech Focus:** Razorpay Payment Gateway integration, Webhook handling, Transaction ledgers in Firestore.

### Phase 4: Pro Features & International Cricket (Months 10-12)
* **Key Features:** International Live Scores, Localization (Hindi, Tamil).
* **Tech Focus:** REST API integrations (CricAPI), Flutter `intl` package for localization.

---

## 5. Testing & QA Strategy

Because scoring mistakes ruin the user experience, QA must be rigorous.

1. **Unit Testing (Mandatory):** 
   * The Scoring Logic (Strike rotation, extra run calculations, over completion) MUST have 100% unit test coverage. We cannot rely on manual testing for cricket rules.
2. **Widget Testing:**
   * Ensure large scoring buttons register taps correctly without overlap.
3. **Network Simulation (Chaos Testing):**
   * Use tools (like Apple Network Link Conditioner) to simulate 2G/Edge networks and complete network drops during a live match to ensure the app doesn't crash and caches data successfully.
4. **Beta Testing Group:**
   * Onboard 5-10 local cricket teams. Have them use the app on weekends using TestFlight / Google Play Internal Testing before public launch.

---

## 6. Release Management

* **Versioning:** Use Semantic Versioning (e.g., `v1.0.0`).
* **CI/CD Deployment:** 
  * Use **Fastlane** integrated with GitHub Actions.
  * Merging to the `release` branch automatically triggers a Fastlane script that builds the Android App Bundle (AAB) and iOS IPA, and pushes them directly to the respective app store consoles.
* **Soft Launch:** Launch only in 1 or 2 targeted cities initially to monitor database costs and scorer behavior before a nationwide marketing push.

---
*End of Implementation Plan*