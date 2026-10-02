# Firestore Rules — Phase 3 Addendum

> **How to apply:** Open your existing `cricket_hub/firestore.rules` and copy each `match /...` block below into it. The existing Phase 1/2 rules stay untouched.

---

## A. Append to `match /users/{userId}` (favorites + bookings sub-collections)

```javascript
// Phase 3: saved grounds + my bookings (mirror)
match /favorite_grounds/{groundId} {
  allow read, write: if owns(userId);
}
match /bookings/{bookingId} {
  allow read: if owns(userId);
  allow write: if false;  // Cloud Functions only.
}
```

## B. Add new top-level rules at the end of `service cloud.firestore`

```javascript
// =========================================================================
// PHASE 3: GROUNDS, BOOKINGS, REVIEWS, UMPIRES, PAYOUTS
// =========================================================================

function isVerifiedGround(groundId) {
  return exists(/databases/$(database)/documents/grounds/$(groundId)) &&
    get(/databases/$(database)/documents/grounds/$(groundId)).data.verified == true &&
    get(/databases/$(database)/documents/grounds/$(groundId)).data.status == 'active';
}

function isVerifiedUmpire(umpireId) {
  return exists(/databases/$(database)/documents/umpires/$(umpireId)) &&
    get(/databases/$(database)/documents/umpires/$(umpireId)).data.verified == true &&
    get(/databases/$(database)/documents/umpires/$(umpireId)).data.status == 'active';
}

// ----- GROUNDS -----
match /grounds/{groundId} {
  allow read: if resource == null
    ? (signedIn() && request.auth.uid == request.resource.data.owner_uid)
    : (
            resource.data.status == 'active' &&
            resource.data.verified == true
          ) || (signedIn() && resource.data.owner_uid == request.auth.uid) || isAdmin();

  allow create: if signedIn() &&
    request.resource.data.owner_uid == request.auth.uid &&
    request.resource.data.status == 'draft' &&
    request.resource.data.verified == false &&
    request.resource.data.keys().hasOnly([
      'name', 'owner_uid', 'city', 'address', 'lat', 'lng',
      'pitch_type', 'amenities', 'photos', 'cover_photo_url',
      'price_weekday_hourly', 'price_weekend_hourly', 'price_full_day',
      'open_time', 'close_time', 'slot_duration_minutes',
      'status', 'verified', 'avg_rating', 'review_count', 'booking_count',
      'ground_stats', 'created_at', 'updated_at'
    ]) &&
    request.resource.data.pitch_type in ['turf', 'matting', 'concrete'] &&
    request.resource.data.price_weekday_hourly is int &&
    request.resource.data.price_weekday_hourly > 0 &&
    request.resource.data.price_weekend_hourly > 0;

  allow update: if signedIn() && resource.data.owner_uid == request.auth.uid &&
    request.resource.data.diff(resource.data).affectedKeys().hasOnly([
      'name', 'city', 'address', 'lat', 'lng',
      'pitch_type', 'amenities', 'photos', 'cover_photo_url',
      'price_weekday_hourly', 'price_weekend_hourly', 'price_full_day',
      'open_time', 'close_time', 'slot_duration_minutes',
      'status', 'updated_at'
    ]) &&
    request.resource.data.verified == resource.data.verified &&
    request.resource.data.avg_rating == resource.data.avg_rating &&
    request.resource.data.review_count == resource.data.review_count &&
    request.resource.data.booking_count == resource.data.booking_count;

  allow update: if isAdmin() &&
    request.resource.data.diff(resource.data).affectedKeys().hasOnly([
      'verified', 'status', 'updated_at'
    ]);

  allow delete: if isAdmin();

  match /slots/{dateIso} {
    allow read: if signedIn() &&
      (isVerifiedGround(groundId) ||
       get(/databases/$(database)/documents/grounds/$(groundId)).data.owner_uid == request.auth.uid);

    allow write: if signedIn() &&
      get(/databases/$(database)/documents/grounds/$(groundId)).data.owner_uid == request.auth.uid &&
      request.resource.data.keys().hasOnly([
        'date', 'slots', 'blocked', 'block_reason', 'generated_at', 'updated_at'
      ]);
  }

  match /blocked_rules/{ruleId} {
    allow read, write: if signedIn() &&
      get(/databases/$(database)/documents/grounds/$(groundId)).data.owner_uid == request.auth.uid;
  }
}

// ----- BOOKINGS -----
match /bookings/{bookingId} {
  allow read: if signedIn() && (
    resource.data.organizer_uid == request.auth.uid ||
    resource.data.counterparty_uid == request.auth.uid ||
    isAdmin()
  );

  allow create: if signedIn() &&
    request.resource.data.organizer_uid == request.auth.uid &&
    request.resource.data.status in ['held', 'pending_payment'] &&
    request.resource.data.kind in ['ground', 'umpire'] &&
    request.resource.data.amount_paise is int &&
    request.resource.data.amount_paise > 0 &&
    request.resource.data.payment_method in ['razorpay', 'cod'] &&
    request.resource.data.keys().hasOnly([
      'kind', 'resource_id', 'resource_name', 'organizer_uid', 'organizer_name',
      'counterparty_uid', 'counterparty_name', 'date', 'slot_start', 'slot_end',
      'duration_minutes', 'amount_paise', 'platform_fee_paise', 'payout_amount_paise',
      'payment_method', 'payment_status', 'status',
      'razorpay_order_id', 'razorpay_payment_id',
      'match_id', 'notes', 'created_at', 'updated_at',
      'qr_token', 'cancellation_reason', 'refund_amount_paise'
    ]);

  allow update: if signedIn() &&
    resource.data.organizer_uid == request.auth.uid &&
    resource.data.status == 'held' &&
    request.resource.data.diff(resource.data).affectedKeys().hasOnly(['notes', 'updated_at']);

  allow update: if signedIn() && resource.data.kind == 'umpire' &&
    resource.data.counterparty_uid == request.auth.uid &&
    resource.data.status == 'pending_payment' &&
    request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status', 'updated_at']) &&
    request.resource.data.status in ['confirmed', 'cancelled'];

  allow update: if signedIn() && resource.data.kind == 'ground' &&
    resource.data.counterparty_uid == request.auth.uid &&
    resource.data.status == 'confirmed' &&
    request.resource.data.diff(resource.data).affectedKeys().hasOnly([
      'status', 'cod_confirmed_at', 'updated_at'
    ]) &&
    request.resource.data.status in ['completed', 'no_show'];

  allow delete: if false;

  match /audit/{logId} {
    allow read: if signedIn() && (
      get(/databases/$(database)/documents/bookings/$(bookingId)).data.organizer_uid == request.auth.uid ||
      get(/databases/$(database)/documents/bookings/$(bookingId)).data.counterparty_uid == request.auth.uid ||
      isAdmin()
    );
    allow write: if false;
  }
}

// ----- REVIEWS -----
match /ground_reviews/{reviewId} {
  allow read: if signedIn();
  allow create: if signedIn() &&
    request.resource.data.reviewer_uid == request.auth.uid &&
    request.resource.data.rating is int &&
    request.resource.data.rating >= 1 && request.resource.data.rating <= 5 &&
    request.resource.data.text.size() <= 500;
  allow update, delete: if isAdmin();
}

match /umpire_reviews/{reviewId} {
  allow read: if signedIn();
  allow create: if signedIn() &&
    request.resource.data.reviewer_uid == request.auth.uid &&
    request.resource.data.rating is int &&
    request.resource.data.rating >= 1 && request.resource.data.rating <= 5 &&
    request.resource.data.text.size() <= 500;
  allow update, delete: if isAdmin();
}

// ----- UMPIRES -----
match /umpires/{uid} {
  allow read: if resource == null
    ? (signedIn() && request.auth.uid == uid)
    : (
            resource.data.status == 'active' &&
            resource.data.verified == true
          ) || (signedIn() && resource.data.user_uid == request.auth.uid) || isAdmin();

  allow create: if signedIn() &&
    request.resource.data.user_uid == request.auth.uid &&
    request.resource.data.status == 'draft' &&
    request.resource.data.verified == false &&
    request.resource.data.day_rate is int &&
    request.resource.data.day_rate > 0;

  allow update: if signedIn() && resource.data.user_uid == request.auth.uid &&
    request.resource.data.diff(resource.data).affectedKeys().hasOnly([
      'display_name', 'phone_number', 'city', 'experience_years',
      'certifications', 'day_rate', 'hourly_rate', 'bio', 'photo_url',
      'status', 'updated_at'
    ]) &&
    request.resource.data.verified == resource.data.verified &&
    request.resource.data.avg_rating == resource.data.avg_rating &&
    request.resource.data.review_count == resource.data.review_count &&
    request.resource.data.matches_officiated == resource.data.matches_officiated;

  allow update: if isAdmin() &&
    request.resource.data.diff(resource.data).affectedKeys().hasOnly([
      'verified', 'status', 'updated_at'
    ]);

  allow delete: if isAdmin();

  match /availability/{dateIso} {
    allow read: if signedIn();
    allow write: if signedIn() &&
      get(/databases/$(database)/documents/umpires/$(uid)).data.user_uid == request.auth.uid &&
      request.resource.data.keys().hasOnly([
        'date', 'slots', 'updated_at'
      ]);
  }
}

// ----- PAYOUTS -----
match /payout_ledger/{ownerUid}/{weekStartIso} {
  allow read: if signedIn() && (request.auth.uid == ownerUid || isAdmin());
  allow write: if false;
}

// ----- RAZORPAY EVENTS -----
match /razorpay_events/{eventId} {
  allow read: if isAdmin();
  allow write: if false;
}
```

> **Note:** This addendum assumes `signedIn()`, `owns()`, `isAdmin()` helpers are already defined at the top of your existing rules file (Phase 2 already defines them).