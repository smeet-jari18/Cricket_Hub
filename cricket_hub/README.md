# CricketHub — Phase 1 + Phase 2

CricketHub is a Flutter/Firebase app for grassroots cricket: offline-first scoring, live match viewing, tournament fixtures and standings, player career stats, and match notifications.

## Phase 2 implementation

| Feature | Implementation |
|---|---|
| Round-robin tournaments | Server-generated single round-robin fixtures; every team plays each other once. Odd-team byes do not create matches. |
| Knockout tournaments | Seeded single-elimination bracket, automatic byes and winner advancement; tied games wait for an organizer tie-break decision. |
| Points table and NRR | Cloud Function recomputes the table from completed match innings. NRR is cumulative runs/overs for minus runs/overs against; an all-out innings counts the full overs quota. |
| Career statistics | Idempotent completion trigger aggregates batting/bowling totals, average, strike rate, economy, milestones, best figures, and recent form. |
| Orange/Purple Caps | Tournament leaders recompute from completed tournament scorecards. |
| Match notifications | FCM match-follow topics send match-start and wicket alerts, with in-app foreground alerts and tap-through to Match Center. |
| Two-innings scorecards | Scoring now saves both innings, result, batting/bowling figures, extras, fall of wickets, and ball-by-ball commentary. |

Cloud Functions source and its pure-domain unit tests live under `functions/`. Firestore rules and indexes are versioned in `firestore.rules` and `firestore.indexes.json`.

## Prerequisites

- Flutter **3.27+** / Dart **3.6+**
- Firebase CLI logged into the `crickethub-dev` project
- Node.js **20** for Cloud Functions
- A configured Android Firebase app (`google-services.json`) and `lib/firebase_options.dart`
- For iOS push notifications: APNs key uploaded in Firebase Console and the Push Notifications capability enabled in Xcode

## Setup

From the `cricket_hub` directory:

```bash
flutter create .       # only if your checkout needs missing platform wrapper files
flutter pub get
flutterfire configure --project=crickethub-dev
flutter run
```

`flutterfire configure` creates the local `lib/firebase_options.dart`; Firebase platform configuration files are intentionally not committed in this source archive. Retain your existing files or configure your own Firebase project.

Enable **Phone** and **Google** sign-in in Firebase Authentication. Create the Firestore database, then deploy the checked-in rules and indexes:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Install, test, and deploy the Phase 2 Cloud Functions:

```bash
npm --prefix functions install
npm --prefix functions test
firebase deploy --only functions
```

The callable endpoints use the `asia-south1` region. Firebase may ask you to enable Cloud Functions/Cloud Build and select a billing plan before the first deployment. Push notifications require Cloud Messaging to be enabled; Android notification permission is requested when a user follows a match.

For a single deployment after login and project setup:

```bash
firebase deploy --only firestore:rules,firestore:indexes,functions
```

## Tests and verification

```bash
flutter test
flutter analyze
npm --prefix functions test
```

The Node tests cover schedule generation, byes, standings, ICC-style all-out NRR overs, results, career aggregation, and tournament leaderboards. Flutter build/analyzer checks still need to be run in an environment with the Flutter SDK and the project's local Firebase configuration.

## Data and attribution notes

- Firestore rules keep account documents (including phone numbers) owner-readable; server-owned career aggregates cannot be edited by clients. Callable Functions require Firebase Authentication and verify tournament ownership; App Check enforcement is currently disabled and should be enabled after registering the production apps.
- A scorer's own stats link by Firebase UID when the recorded player name matches their profile. Other player names link automatically only when there is exactly one matching normalized profile name. Ambiguous names stay in server-owned `player_stats` rather than being incorrectly assigned to an account; stable player IDs/invites are a future roster improvement.
- Tournament results and NRR are based on completed two-innings scorecards. DLS/rain adjustments and super overs are not implemented. A tied knockout fixture therefore requires the organizer to choose which team advances.
- FCM delivery and Cloud Functions are **not deployed automatically** by the source changes. Deploy them to the configured Firebase project and configure APNs before expecting device notifications.

## Earlier platform setup note

For Android builds, use JDK 17 with the Gradle wrapper. If the project and Pub cache are on different Windows drives, set `PUB_CACHE` to a directory on the same drive as the checkout before `flutter pub get`.
