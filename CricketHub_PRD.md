# Product Requirements Document (PRD): CricketHub

## Document Info
| Attribute | Details |
| :--- | :--- |
| **Project Name** | CricketHub |
| **Document Version** | 1.0.0 |
| **Author** | Smeet Jariwala , Aman Sinha |
| **Date** | September 21, 2026 |
| **Status** | Approved for Development |
| **Target Platforms** | iOS, Android (Flutter) |

---

## Executive Summary
CricketHub is a mobile-first ecosystem designed to professionalize grassroots and local tournament cricket. By providing an intuitive, offline-first scoring interface, real-time live score distribution, and automated statistics generation, CricketHub bridges the gap between international cricket broadcasting and weekend local matches. Our vision is to become the ultimate hub for amateur cricketers to track their careers, organizers to seamlessly run tournaments, and local businesses (grounds, umpires) to monetize their inventory. 

---

## Problem Statement & Opportunity
Millions of amateur cricketers play weekly, yet grassroots cricket remains highly disorganized. 
* **Scorers & Players:** Matches are scored on paper or basic note apps. Ball-by-ball data, career statistics, and match records are permanently lost.
* **Organizers:** Managing tournaments, calculating net run rates (NRR), and updating points tables manually via WhatsApp or Excel is tedious and error-prone.
* **Fans/Family:** Unable to follow local matches live unless physically present at the ground.
* **Logistics:** Booking grounds and certified umpires requires fragmented phone calls and lacks transparency in pricing and availability.

**The Opportunity:** By digitizing the local cricket experience with a user-friendly Flutter/Firebase app, we can aggregate a highly engaged demographic of sports enthusiasts, ultimately monetizing through ecosystem transactions (ground/umpire booking) and premium analytics.

---

## Goals & Objectives

### Business Goals
1. **User Acquisition:** Acquire 50,000 registered users (players, scorers, organizers) within 12 months of Phase 1 launch.
2. **Tournament Adoption:** Onboard 500 local tournaments by the end of Phase 2.
3. **Monetization:** Generate $10,000+ in Gross Merchandise Value (GMV) monthly via ground and umpire bookings within 6 months of Phase 3 launch.

### User Goals
1. Provide players with a professional-grade "Career Profile" detailing runs, wickets, averages, and strike rates.
2. Enable scorers to digitally record matches seamlessly, even in areas with zero internet connectivity.
3. Allow organizers to create a tournament and let the system automatically handle points tables and NRR.
4. Give fans an ESPNcricinfo-like live viewing experience for their friends' local matches.

---

## Non-Goals (Out of Scope)
To maintain focus on our core value proposition, the following are explicitly **Out of Scope** for Phases 1 through 4:
* Fantasy cricket or prediction games.
* Real-money betting or gambling integration.
* Live video streaming of matches (we provide live *data/scores*, not video).
* E-commerce functionality for selling cricket gear (bats, balls, etc.).
* Detailed design, UI, and Database schemas for "Umpire Booking" (This is explicitly deferred until Phase 3).

---

## Success Metrics / KPIs
1. **Engagement:** Active players play/track > 2 matches per month.
2. **Retention:** Day-30 (D30) Retention Rate > 25%.
3. **Feature Adoption:** > 80% of matches created utilize the ball-by-ball scoring feature.
4. **Offline Reliability:** > 99% successful cloud sync rate for matches scored in offline mode.
5. **Virality/Viewing:** Average of 15+ unique live viewers per active match.

---

## Target Users & Personas

### 1. Rahul (The Passionate Player)
* **Demographics:** 24, Software Engineer, plays club cricket every weekend.
* **Goals:** Wants to track his career stats, improve his game, and share his milestones (e.g., 50 runs, 5 wickets) on social media.
* **Pain Points:** Loses track of how many runs he scored over the season; tired of arguing over wrong scores recorded in paper books.

### 2. Vikram (The Tournament Organizer)
* **Demographics:** 35, Local sports club owner.
* **Goals:** Host a 16-team knockout and round-robin tournament efficiently. Keep all team captains updated.
* **Pain Points:** Calculating NRR and updating the points table every night takes hours. Dealing with scheduling conflicts.

### 3. Amit (The Scorer)
* **Demographics:** 19, College student who scores matches for extra pocket money.
* **Goals:** Score matches accurately and quickly without missing the on-field action.
* **Pain Points:** Network coverage at local grounds is terrible. Complex scoring apps make him record data too slowly, leading to disputes with umpires. Needs one-hand usability.

### 4. Neha (The Fan/Supporter)
* **Demographics:** 22, Rahul’s friend.
* **Goals:** Wants to know how Rahul’s team is doing without having to sit at the ground all day in the sun.
* **Pain Points:** Constantly texting players for score updates, which they can't answer while fielding.

---

## User Stories

| ID | Persona | User Story | Acceptance Criteria | Priority (MoSCoW) | Phase |
| :--- | :--- | :--- | :--- | :--- | :--- |
| US-01 | Player | As a Player, I want to log in via phone OTP so that I don't have to remember a password. | OTP sent via SMS. Successful auth creates Firebase user doc. | Must Have | 1 |
| US-02 | Organizer | As an Organizer, I want to create a team and add players via phone number so that our squad is ready. | Can create team, upload logo. Can search players by phone to add to roster. | Must Have | 1 |
| US-03 | Scorer | As a Scorer, I want to record ball-by-ball events (runs, extras, wickets) completely offline so that bad networks don't stop the match. | Scoring screen functions without network. Data caches locally. Syncs to Firestore automatically upon reconnection. | Must Have | 1 |
| US-04 | Scorer | As a Scorer, I want to easily undo the last ball so that I can correct accidental taps. | "Undo" button reverses the last ball's state (score, strike rotation, stats). Maintains an audit log. | Must Have | 1 |
| US-05 | Fan | As a Fan, I want to see live score updates within seconds so that I feel connected to the game. | Live match screen updates via Firestore snapshot streams < 2s after scorer syncs. | Must Have | 1 |
| US-06 | Organizer | As an Organizer, I want to create a round-robin tournament so that the app generates a schedule and points table. | Can define teams, groups, win/loss/tie points. Points table updates automatically post-match. | Must Have | 2 |
| US-07 | Player | As a Player, I want to see my career stats aggregated automatically so that I can prove my skills. | Profile shows Total Runs, Wickets, AVG, SR, Econ. Updated via Cloud Functions post-match. | Must Have | 2 |
| US-08 | Fan | As a Fan, I want a push notification when a wicket falls or a match starts so I don't miss key moments. | User can "subscribe" to a match/team. FCM sends notification on specific triggers. | Should Have | 2 |
| US-09 | Organizer | As an Organizer, I want to browse and book a ground for my match so that I can secure a venue instantly. | Ground list view with availability calendar. Slot selection and Razorpay integration. | Must Have | 3 |
| US-10 | Fan | As a Fan, I want to view international cricket live scores so that I use CricketHub as my only cricket app. | Dedicated "International" tab pulling data from CricAPI. | Could Have | 4 |

---

## Functional Requirements

### Module 1: Authentication & User Management
* **FR-AUTH-01 (Priority: High):** The system shall support Phone Number (OTP) and Google Sign-In via Firebase Auth.
* **FR-AUTH-02 (Priority: High):** Users shall complete a profile indicating their primary role (Batsman, Bowler, All-rounder) and batting/bowling style.

### Module 2: Teams & Matches
* **FR-TEAM-01 (Priority: High):** Any user can create a Team by providing a Name, Logo, and Location.
* **FR-TEAM-02 (Priority: High):** Team Admins can add players by searching registered users or generating a unique invite link.
* **FR-MAT-01 (Priority: High):** A user can create a Match by selecting two existing teams, setting overs (e.g., T20, T10), ball type (Tennis, Leather), and assigning a Scorer.

### Module 3: Ball-by-Ball Scoring (Offline-First)
* **FR-SCORE-01 (Priority: Critical):** The scoring UI must allow logging of runs (0-6), extras (Wide, No Ball, Bye, Leg Bye), and wickets (Bowled, Caught, LBW, Run Out, etc.).
* **FR-SCORE-02 (Priority: Critical):** System must auto-rotate strike at the end of an over and on odd runs (1, 3, 5).
* **FR-SCORE-03 (Priority: Critical):** Local caching (using Riverpod + local DB like Hive/Isar) must store all match events if offline. Network availability listener will trigger Firestore batch sync once online.
* **FR-SCORE-04 (Priority: High):** System must strictly allow *only* the assigned Scorer to edit the match data via Firestore Security Rules.

### Module 4: Live Score Viewing
* **FR-LIVE-01 (Priority: High):** Live dashboard showing Current Score, Run Rate, Required Run Rate, Current Batsmen (with stats), and Current Bowler.
* **FR-LIVE-02 (Priority: Medium):** Ball-by-ball text commentary generated dynamically (e.g., "Bhuvi to Kohli, 4 runs, driven through covers!").

### Module 5: Tournaments
* **FR-TRN-01 (Priority: High):** Support Knockout and Round-Robin formats.
* **FR-TRN-02 (Priority: High):** Automatic Points Table calculation including Net Run Rate (NRR) based on standard ICC formulas.

### Module 6: Statistics & Leaderboards
* **FR-STAT-01 (Priority: High):** Firebase Cloud Functions shall aggregate match data into player documents upon match completion (Total Runs, Wickets, 50s, 100s, 5Ws).
* **FR-STAT-02 (Priority: Medium):** Tournament-specific leaderboards for "Orange Cap" (most runs) and "Purple Cap" (most wickets).

### Module 7: Ground & Umpire Booking (Phase 3)
* **FR-BOOK-01 (Priority: High):** Ground Owners can list venues, set hourly/daily pricing, and block unavailable dates.
* **FR-BOOK-02 (Priority: High):** Organizers can select time slots and pay a booking advance via Razorpay.
* **FR-BOOK-03 (Priority: Medium):** Bookings generate a unique ID and QR code for verification at the venue.

---

## Screen-by-Screen Breakdown

1. **Onboarding & Auth Flow**
   * **Splash Screen:** App logo, initializes Firebase and local caches.
   * **Login/Signup:** Phone number input, OTP verification, Google Sign-In button.
   * **Profile Setup:** Name, profile picture upload, player type selection.

2. **Main Navigation (Bottom Bar)**
   * **Home:** Live local matches, trending tournaments, quick "Start Match" FAB (Floating Action Button).
   * **My Cricket:** User's teams, upcoming matches, career stats summary.
   * **Tournaments:** Explore local tournaments, points tables, and leaderboards.
   * **More/Menu:** Ground booking, Umpire booking, settings, profile.

3. **Team & Match Creation**
   * **Create Team:** Form with Team Name, City, upload logo. Roster management list.
   * **Create Match:** Select Team A & B, choose format (Overs), select location/ground, assign scorer. Toss selection screen (Who won? Bat or Bowl first?).

4. **Scoring Dashboard (The most critical screen)**
   * **Top:** Large current score (e.g., 145/4), Over count (15.2), Current Run Rate.
   * **Middle:** Current Batsmen (Striker highlighted), Current Bowler stats for the spell.
   * **Bottom (Action Pad):** Large, thumb-friendly buttons for runs (0, 1, 2, 3, 4, 6), Extras (WD, NB, B, LB), Wicket, and Undo.
   * **Drawer:** Full scorecard access, partner swap, retire hurt options.

5. **Live Match View & Scorecard**
   * **Summary Tab:** High-level overview, mini-scorecard, recent balls.
   * **Scorecard Tab:** Traditional full batting and bowling card, fall of wickets (FOW).
   * **Commentary Tab:** Vertical feed of ball-by-ball textual data.

6. **Tournament Hub**
   * **Overview:** About, rules, participating teams.
   * **Fixtures:** Schedule of matches.
   * **Points Table:** Ranked list with P, W, L, T, PTS, NRR.
   * **Stats:** Tournament leaders (Runs, Wickets, Sixes).

7. **Ground Booking (Phase 3)**
   * **Ground Listing:** Search with filters (city, price, pitch type: turf/matting).
   * **Ground Details:** Photos, amenities (floodlights, pavilion), reviews.
   * **Slot Picker:** Calendar view with available/booked time slots.
   * **Checkout:** Razorpay integration for advance payment.

---

## Non-Functional Requirements

1. **Performance:** Live score updates must reflect on the fan's device within 2 seconds of the scorer recording the ball (under good network conditions). 
2. **Offline Support:** The app must be fully operable for the Scorer in airplane mode. Caching must hold at least 5 complete matches (approx. 5MB) locally before requiring a sync.
3. **Security & Access Control:**
   * Firebase Security Rules must ensure `write` access to a match document is strictly limited to the `scorer_id` or `admin_id`.
   * PII (Phone numbers) must be encrypted/hidden from public profiles.
4. **Scalability:** The Firestore data model must prevent "hot spots". Ball-by-ball data must be stored in subcollections (`matches/{matchId}/balls`) rather than bloating the main match document.
5. **Accessibility:** The Scoring screen must support dark mode (to reduce glare in sunlight) and have touch targets of at least 48x48dp to prevent mis-taps.

---

## Technical Considerations

### High-Level Architecture
* **Frontend:** Flutter (Dart). Unified codebase for iOS and Android.
* **State Management:** Riverpod. Ideal for managing complex local states (like the scoring engine) and asynchronous streams (live Firestore updates).
* **Backend:** Firebase ecosystem.
  * **Auth:** Managing identities.
  * **Firestore:** NoSQL document database for teams, matches, stats.
  * **Cloud Storage:** Team logos, user avatars, ground images.
  * **Cloud Functions (Node.js):** Backend logic for NRR calculation, stats aggregation, and Razorpay webhook handling.
  * **Cloud Messaging (FCM):** Push notifications.

### Firestore Data Model (Core Collections)
* `/users/{userId}`: Profile info, career stats summary.
* `/teams/{teamId}`: Team details, array of `playerIds`.
* `/tournaments/{tournamentId}`: Tournament config, points table map.
* `/matches/{matchId}`: Match metadata, current score summary, status (live, completed).
  * `/matches/{matchId}/balls/{ballId}`: (Subcollection) Individual ball events (run, extra, wicket).
* `/grounds/{groundId}`: Ground details.
* `/bookings/{bookingId}`: Booking status, payment reference.

### Third-Party Dependencies
* **Razorpay SDK:** For processing Indian payments (UPI, Cards, NetBanking).
* **CricAPI (or similar):** For Phase 4 international match data ingestion.
* **Isar / Hive:** Extremely fast local NoSQL database for Flutter to handle offline-first scoring before pushing to Firestore.

### Push Notification Flow
1. User clicks "Follow" on a Match. Device FCM token is added to a Firestore array or Pub/Sub topic.
2. Scorer clicks "Wicket" or "End of Match".
3. Firestore triggers a Cloud Function `onWrite`.
4. Cloud Function formats the payload and sends it to FCM via Admin SDK.
5. Fans receive rich push notifications.

---

## Release Plan

| Phase | Milestone / Features | Target Timeline |
| :--- | :--- | :--- |
| **Phase 1 (MVP)** | Auth, Profile, Create Teams, Create Matches, Offline Scoring, Live Viewing, Basic Shareable Scorecard. | Month 1 - 3 |
| **Phase 2** | Tournaments, Auto Points Table, NRR, Career Stats aggregation, Push Notifications (Wickets/Match End). | Month 4 - 6 |
| **Phase 3** | Ground Owner Panel, Ground listing, Calendar Slot Booking, Umpire Booking, Razorpay Payments. | Month 7 - 9 |
| **Phase 4** | Integration of CricAPI, International Match Center, Localization (Hindi, Tamil, etc.). | Month 10 - 12 |

---

## Risks & Mitigations

| Risk | Impact | Mitigation Strategy |
| :--- | :--- | :--- |
| **1. Network Dead Zones** at local grounds cause score sync failures. | High | Implement robust offline-first architecture using local databases (Isar/Hive). Only sync delta changes upon network reconnection. |
| **2. Scorer Errors/Disputes** leading to abandoned app usage. | High | Build a robust "Undo" log with an audit trail. Allow the opposing captain to "Verify" the match scorecard post-match. |
| **3. High Firebase Database Costs** due to millions of read/writes per match. | High | Do not stream all ball-by-ball reads for live fans. Aggregate over summaries at the match document level. Use pagination for scorecards. |
| **4. Low Scorer Adoption** due to app complexity. | Medium | Design a specialized, uncluttered "Scoring Mode" UI. Use very large buttons and one-hand ergonomics. Provide an interactive tutorial. |
| **5. Fake Teams & Data Spam** bloating the system. | Medium | Implement rate-limiting via App Check. Add a "Verified Tournament" badge to distinguish legitimate professional local matches. |
| **6. App Store Rejection** (UGC policies). | Medium | Implement basic report/block features for inappropriate team names or user profiles to comply with Apple/Google UGC guidelines. |

---

## Assumptions, Dependencies & Open Questions

* **Assumptions:** 
  * Target users have smartphones running at least Android 8.0 or iOS 13.
  * Local organizers are willing to mandate digital scoring for their tournaments.
* **Dependencies:**
  * Approval of Google Play Developer and Apple Developer accounts.
  * Razorpay merchant account approval for marketplace payments (Grounds).
* **Open Questions (For next Sprint Grooming):**
  * *Should we allow partial match scoring? (e.g., scoring starts from the 5th over because the scorer was late).*
  * *How do we handle rain interruptions (DLS method)? For MVP, we will allow manual over reduction, but DLS calculation might be complex for Phase 1.*

---

## Glossary
* **MVP:** Minimum Viable Product.
* **MoSCoW:** Prioritization technique (Must have, Should have, Could have, Won't have).
* **Over:** A set of 6 legal deliveries bowled by a single bowler.
* **Wicket:** The dismissal of a batsman.
* **Strike Rate (Batting):** (Total Runs / Total Balls Faced) * 100.
* **Economy Rate (Bowling):** Total Runs Conceded / Total Overs Bowled.
* **NRR (Net Run Rate):** A statistical method used in tournaments to rank teams with equal points.
* **FOW (Fall of Wickets):** The team's score when each batsman is dismissed.