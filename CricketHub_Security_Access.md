# Security & Access Control Document: CricketHub

## Document Info
| Attribute | Details |
| :--- | :--- |
| **Project Name** | CricketHub |
| **Document Version** | 1.1.0 |
| **Author** | Solo Developer |
| **Technology Focus** | Firebase (Auth, Firestore, Storage), Flutter |
| **Date** | October 2023 / Updated Today |

---

## 1. Authentication Strategy
All access to CricketHub requires authentication via **Firebase Authentication**.
* **Supported Providers:** Phone Number (SMS OTP) and Google Sign-In.
* **Session Management:** Firebase Auth handles token generation automatically.
* **Anonymous Access:** Not allowed for Phase 1. Users must create an account to view live scores.

---

## 2. Role-Based Access Control (RBAC) Matrix
| Role | Permissions & Access |
| :--- | :--- |
| **Player (Fan)** | Can read all live matches, teams, and profiles. Can only edit their *own* profile. |
| **Team Admin** | Can edit team details, add/remove players. *Cannot* edit match scores. |
| **Tournament Admin** | Can manage the tournament schedule. |
| **Scorer** | **Exclusive write access** to update the score for their specific match. |

---

## 3. Firestore Security Rules (Data Protection)
To prevent client-side manipulation, rules are strictly enforced at the database level.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAuthenticated() {
      return request.auth != null;
    }

    // 1. USER PROFILES
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && request.auth.uid == userId;
    }

    // 2. TEAMS
    match /teams/{teamId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && request.auth.uid == resource.data.admin_uid;
    }

    // 3. MATCHES & LIVE SCORES
    match /matches/{matchId} {
      allow read: if isAuthenticated(); 
      allow create: if isAuthenticated(); 
      allow update, delete: if isAuthenticated() && 
        (request.auth.uid == resource.data.scorer_uid || 
         request.auth.uid == resource.data.tournament_admin_uid);
         
      // 4. BALLS (Sub-collection)
      match /balls/{ballId} {
        allow read: if isAuthenticated();
        allow write: if isAuthenticated() && 
          get(/databases/$(database)/documents/matches/$(matchId)).data.scorer_uid == request.auth.uid;
      }
    }
    
    // 5. BOOKINGS (Phase 3)
    match /bookings/{bookingId} {
      allow read, create: if isAuthenticated() && request.auth.uid == request.resource.data.user_id;
      allow update: if false; 
    }
  }
}