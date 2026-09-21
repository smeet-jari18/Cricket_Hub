# Backend Database Schema (Firestore): CricketHub

## Document Info
| Attribute | Details |
| :--- | :--- |
| **Project Name** | CricketHub |
| **Document Version** | 1.1.0 |
| **Author** | Solo Developer |
| **Database Type** | NoSQL (Firebase Cloud Firestore) |
| **Date** | October 2023 / Updated Today |

---

## Architecture Note (NoSQL vs SQL)
Unlike a traditional relational database (SQL), Firestore does not use foreign key constraints. We purposefully **denormalize** some data (like team names or player names inside the match document) to prevent the client app from having to make dozens of separate database queries just to render one screen. 

---

## 1. Collection: `users`
**Purpose:** Stores user authentication details, profile info, and aggregated career statistics.
* **Document ID:** `{firebase_auth_uid}`

| Field Name | Data Type | Description / Example |
| :--- | :--- | :--- |
| `phone_number` | String | Encrypted or hidden via rules. e.g., "+919876543210" |
| `display_name` | String | e.g., "Rahul Sharma" |
| `avatar_url` | String | URL to Firebase Cloud Storage image |
| `role` | String | "player", "organizer", "scorer" |
| `player_profile` | Map | Sub-fields: `batting_style`, `bowling_style` |
| `career_stats` | Map | Aggregated total runs, wickets, etc. |
| `created_at` | Timestamp | Server timestamp of account creation |

---

## 2. Collection: `teams`
**Purpose:** Stores team details and the list of players inside that team.
* **Document ID:** `{team_id}`

| Field Name | Data Type | Description / Example |
| :--- | :--- | :--- |
| `team_name` | String | e.g., "Mumbai Strikers" |
| `city` | String | e.g., "Mumbai" |
| `admin_uid` | String | UID of the user who created the team |
| `logo_url` | String | URL to Firebase Storage image |
| `roster` | Array | List of Player UIDs in this team |

---

## 3. Collection: `matches` (Crucial for Live Viewing)
**Purpose:** Stores match setup details and the live summary for fans.
* **Document ID:** `{match_id}`

| Field Name | Data Type | Description / Example |
| :--- | :--- | :--- |
| `status` | String | "scheduled", "live", "completed", "abandoned" |
| `team_a_id` | String | UID of Team A |
| `team_b_id` | String | UID of Team B |
| `toss` | Map | `winner_id` and `elected_to` ("bat" or "bowl") |
| `scorer_uid` | String | UID of the assigned scorer |
| `current_summary` | Map | Live score, wickets, overs, striker_id, bowler_id |

---

## 4. Sub-Collection: `matches/{match_id}/balls`
**Purpose:** Stores every single ball. Used for offline-first syncing.
* **Document ID:** `{ball_id}` (e.g., "over1ball_1")

| Field Name | Data Type | Description / Example |
| :--- | :--- | :--- |
| `over_number` | Number | e.g., 1 |
| `ball_number` | Number | e.g., 1 to 6 |
| `runs` | Number | 0, 1, 2, 3, 4, 6 |
| `extras` | Map | `type` ("wide", "no_ball", "bye", "leg_bye") and `runs` |
| `wicket` | Map or Null | `type` ("bowled", "caught"), `player_out_id` |
| `timestamp` | Timestamp | Exact time the ball was recorded |

---

## 5. Collection: `tournaments` (Phase 2)
**Purpose:** Groups matches together with automatic points tables.
* **Document ID:** `{tournament_id}`

| Field Name | Data Type | Description / Example |
| :--- | :--- | :--- |
| `format` | String | "Knockout" or "Round-Robin" |
| `points_config`| Map | Points awarded: `win=2`, `tie=1`, `loss=0` |
| `points_table` | Map | Team IDs mapped to Points, Wins, Losses, NRR |

---

## 6. Collections: `grounds` & `bookings` (Phase 3)
**Purpose:** Manages the marketplace for renting cricket grounds.
* **grounds:** `name`, `location`, `price`, `facilities`, `owner_uid`, `photos`
* **bookings:** `ground_id`, `user_id`, `date`, `slot`, `amount`, `payment_status`