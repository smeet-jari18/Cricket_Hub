# Security & Access Control Document: CricketHub

## Document Info
| Attribute | Details |
| :--- | :--- |
| **Project Name** | CricketHub |
| **Document Version** | 1.0.0 |
| **Author** | Lead Backend Engineer / Security Architect |
| **Technology Focus** | Firebase (Auth, Firestore, Functions), Flutter |
| **Date** | October 24, 2023 |

---

## 1. Authentication Strategy

All access to CricketHub requires authentication via **Firebase Authentication**.

* **Supported Providers:** 
  1. Phone Number (SMS OTP) - Primary method for players in the Indian subcontinent.
  2. Google Sign-In (OAuth 2.0).
* **Session Management:** Firebase Auth handles token generation, storage, and automatic refresh (ID tokens expire every hour).
* **Anonymous Access:** Not allowed for Phase 1. Users must create an account to view live scores to build our user base and prevent unauthenticated bot scraping.

---

## 2. Role-Based Access Control (RBAC) Matrix

Access levels are determined by the user's relationship to the data document.

| Role | Definition | Permissions & Access |
| :--- | :--- | :--- |
| **Player (Fan)** | Default authenticated user. | Can read all live matches, teams, and public profiles. Can only edit their *own* profile. |
| **Team Admin** | User who created a `team`. | Can edit team details, add/remove players to the roster. Cannot edit match scores. |
| **Tournament Admin** | User who created a `tournament`. | Can manage tournament schedule, add teams. Can override match settings within their tournament. |
| **Scorer** | User explicitly assigned to a `match`. | **Exclusive write access** to update the score and ball-by-ball data for that specific match. |
| **System Admin** | CricketHub internal staff. | Managed via Firebase Custom Claims (`admin: true`). Can moderate UGC (User Generated Content) and ban users. |

---

## 3. Firestore Security Rules (Data Protection)

To prevent client-side manipulation (e.g., a user modifying the app code to give their team more runs), security rules must be strictly enforced at the database level.

### 3.1 Base Rules & User Profiles
Users can only modify their own data. Personally Identifiable Information (PII), such as phone numbers, must be protected.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Global function to check auth
    function isAuthenticated() {
      return request.auth != null;
    }

    // USER PROFILES
    match /users/{userId} {
      // Anyone logged in can view a profile (Career stats are public)
      allow read: if isAuthenticated();
      // Only the account owner can update their profile
      allow write: if isAuthenticated() && request.auth.uid == userId;
    }