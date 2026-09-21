# Backend Database Schema (Firestore): CricketHub

## Document Info
| Attribute | Details |
| :--- | :--- |
| **Project Name** | CricketHub |
| **Document Version** | 1.0.0 |
| **Author** | Lead Backend Engineer / System Architect |
| **Database Type** | NoSQL (Firebase Cloud Firestore) |
| **Date** | October 24, 2023 |

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
| `player_profile` | Map | Sub-fields: `batting_style` (String: "Right-hand"), `bowling_style` (String: "Leg-break") |
| `career_stats` | Map | **See breakdown below** |
| `created_at` | Timestamp | Server timestamp of account creation |

**`career_stats` Map Breakdown:**
```json
{
  "matches_played": 45,
  "batting": {
    "runs": 1205,
    "balls_faced": 850,
    "highest_score": 88,
    "fifties": 6,
    "hundreds": 0
  },
  "bowling": {
    "wickets": 32,
    "runs_conceded": 640,
    "overs_bowled": 110.5,
    "five_wicket_hauls": 1
  }
}