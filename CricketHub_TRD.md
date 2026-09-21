# Technical Requirements Document (TRD): CricketHub

## Document Info
| Attribute | Details |
| :--- | :--- |
| **Project Name** | CricketHub |
| **Document Version** | 1.0.0 |
| **Author** | Lead Technical/Product Manager |
| **Date** | October 24, 2023 |
| **Status** | Approved for Architecture Phase |
| **Associated PRD** | CricketHub_PRD_v1.0 |

---

## 1. System Architecture Overview

CricketHub utilizes a **Serverless Mobile Architecture**. The client app heavily relies on local caching for offline capabilities and synchronizes directly with Firebase as a Backend-as-a-Service (BaaS).

### High-Level Architecture Flow
1. **Client Layer:** Flutter app on iOS/Android. Handles UI, State Management (Riverpod), and Local Storage (Isar).
2. **Connectivity Layer:** Internet connection observer. Routes data to Local DB if offline, or directly to Firebase if online.
3. **Cloud Layer (Firebase):** Firestore (Database), Cloud Functions (Backend compute), Cloud Storage (Media), Cloud Messaging (Push notifications).
4. **Third-Party Layer:** Razorpay (Payments in Phase 3), CricAPI (Live intl scores in Phase 4).

---

## 2. Technology Stack

### Frontend (Mobile App)
* **Framework:** Flutter (v3.13+) / Dart (v3.1+)
* **State Management:** Riverpod (Providers for isolated states: Auth, MatchScore, LiveViewer)
* **Routing:** GoRouter (Deep-linking support for sharing matches)
* **Local Database:** Isar (Extremely fast, NoSQL DB for offline scoring caching)
* **Network/API:** `dio` or `http` (for third-party APIs), `cloud_firestore` (for Firebase)

### Backend (Firebase BaaS)
* **Authentication:** Firebase Auth (Phone/OTP, Google OAuth)
* **Database:** Cloud Firestore (NoSQL document database)
* **Storage:** Firebase Cloud Storage (Images, Team Logos)
* **Compute:** Firebase Cloud Functions (Node.js 18, TypeScript)
* **Notifications:** Firebase Cloud Messaging (FCM)
* **Security:** Firebase App Check (reCAPTCHA Enterprise / App Attest) to prevent API abuse.

---

## 3. Data Model (Firestore Schema)

To optimize reads/writes and prevent "hot spots", we will use a top-level collection structure with targeted sub-collections.

### `users` (Collection)
* `uid` (Document ID)
* `phone_number` (String, encrypted/hidden via rules)
* `display_name` (String)
* `role` (String - player, organizer, ground_owner)
* `stats` (Map) -> `total_runs`, `total_wickets`, `matches_played`

### `teams` (Collection)
* `team_id` (Document ID)
* `team_name` (String)
* `admin_uid` (String)
* `roster` (Array of Strings - UIDs of players)
* `logo_url` (String)

### `matches` (Collection) - *Crucial for Live Viewing*
* `match_id` (Document ID)
* `status` (String: scheduled, live, completed, abandoned)
* `team_a_id`, `team_b_id` (Strings)
* `toss_winner_id`, `elected_to` (String - bat/bowl)
* `scorer_uid` (String - Determines who has write access)
* `current_summary` (Map) -> `score`, `wickets`, `overs`, `striker_id`, `non_striker_id`, `bowler_id` *(Updated every ball, read by Live Viewers).*
  
#### `matches/{match_id}/balls` (Sub-collection) - *Crucial for Cost Management*
* `ball_id` (Document ID - e.g., "over_1_ball_1")
* `over_number` (Int), `ball_number` (Int)
* `runs` (Int)
* `extras` (Map) -> `type` (wide, no_ball, etc.), `runs`
* `wicket` (Map/Null) -> `type`, `player_out_id`, `catcher_id`
* `timestamp` (ServerTimestamp)

### `tournaments` (Collection)
* `tournament_id` (Document ID)
* `points_table` (Map/Array) -> Team IDs mapped to P, W, L, PTS, NRR.

---

## 4. Offline-First Synchronization Strategy

The Scoring Screen must never freeze due to poor network conditions at cricket grounds.

### Data Flow (Scoring a Ball)
1. Scorer taps "4 Runs".
2. **Local Write:** App writes the ball event to the **Isar local database** and immediately updates the local Riverpod state. The UI updates instantly.
3. **Queue Creation:** The event is added to a local sync queue.
4. **Network Check:** 
   * If **Offline**: Event stays in queue. App shows a "Sync Pending" icon.
   * If **Online**: A background worker (using Flutter `workmanager` or custom stream listener) reads the queue.
5. **Batch Cloud Write:** App executes a `WriteBatch` to Firestore, updating both the `matches/{matchId}` summary and writing to the `balls` subcollection.
6. **Acknowledge:** On success, the event is removed from the local Isar queue.

---

## 5. Firebase Cloud Functions (Server-Side Logic)

Client apps should not calculate global stats or Net Run Rates (to prevent manipulation and ensure consistency). 

* **`onMatchComplete` (Firestore Trigger):**
  * Triggered when a match status changes to "completed".
  * Iterates through the scorecard.
  * Updates `stats` inside `users/{userId}` for all participating players.
  * If part of a tournament, triggers NRR recalculation and updates `tournaments/{tournamentId}`.
* **`onWicketOrMatchStart` (Firestore Trigger):**
  * Triggered on specific match updates.
  * Queries FCM tokens of users subscribed to the match/team.
  * Sends Push Notifications.
* **`razorpayWebhook` (HTTP Trigger - Phase 3):**
  * Listens for `payment.authorized` and `payment.failed` from Razorpay.
  * Secures/updates the ground booking document in Firestore securely.

---

## 6. Security & Access Control (Firestore Rules)

Strict rules are required to prevent data tampering.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can only edit their own profile
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Only the assigned scorer or tournament admin can update a match
    match /matches/{matchId} {
      allow read: if true; // Fans can view live scores
      allow update: if request.auth != null && 
                    (request.auth.uid == resource.data.scorer_uid || 
                     request.auth.uid == resource.data.tournament_admin_uid);
      
      // Balls subcollection follows the same logic
      match /balls/{ballId} {
        allow read: if true;
        allow write: if request.auth != null && 
                     get(/databases/$(database)/documents/matches/$(matchId)).data.scorer_uid == request.auth.uid;
      }
    }
  }
}