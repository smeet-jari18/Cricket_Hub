# ✅ Phase 3 — Console Setup Checklist

> **Tumhara kaam** (jo manually karna hai, jaise Phase 1 me Firebase setup kiya tha). Main ne code likh diya hai, but ye cloud/console setup manually karna padega.

---

## 🎯 Quick overview

| Task | Where | Time | Difficulty |
|---|---|---|---|
| 1. Razorpay account + test keys | razorpay.com | 10 min | Easy |
| 2. Firebase project (already done in Phase 1) | console.firebase.google.com | — | Done |
| 3. Flutter side: pubspec + lib/ files | your local code | 5 min | Easy |
| 4. Firebase Secrets (4 secrets) | firebase CLI | 5 min | Easy |
| 5. Update Firestore rules + indexes | firebase CLI | 5 min | Easy |
| 6. Deploy Cloud Functions | firebase CLI | 10 min | Medium |
| 7. Enable billing (Blaze plan) | console.firebase.google.com | 5 min | Important |
| 8. Configure Razorpay webhook URL | razorpay dashboard | 2 min | Easy |
| 9. Test end-to-end | emulator + real device | 30 min | Medium |
| **Total** | | **~70 min** | |

---

## Step 1: Razorpay account + test keys

### 1.1 Create account
- Go to: https://dashboard.razorpay.com/
- Sign up (free)
- Complete KYC (instant for test mode)

### 1.2 Generate test keys
- Settings → API Keys → Toggle to **Test Mode**
- Click "Generate Test Key"
- You'll get:
  - `Key ID` (starts with `rzp_test_...`)
  - `Key Secret` (shown only once — copy it!)
- **Save these 2 values securely** — you'll need them in Step 4

### 1.3 Get webhook secret
- Settings → Webhooks → "Create New Webhook"
- URL: leave blank for now (you'll add in Step 8)
- Active Events: select `payment.captured`, `payment.failed`, `refund.processed`
- Click "Create"
- **Copy the Webhook Secret** (shown only once)

### 1.4 Generate a QR token secret (any random string)
Run in terminal:
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```
Output: `a1b2c3d4e5f6...` — save this as `QR_JWT_SECRET`.

---

## Step 2: Firebase project — already done ✅

Your `crickethub-dev` project is already set up. Skip this step.

> **Note:** If you want Phase 3 to run on a separate project (recommended for testing), create a new Firebase project: https://console.firebase.google.com/ → Add Project → `crickethub-phase3-dev`. Then run `flutterfire configure` against that project.

---

## Step 3: Flutter side — add packages and copy files

### 3.1 Append to `cricket_hub/pubspec.yaml`
Add under `dependencies:` (don't change existing lines, just add):
```yaml
  razorpay_flutter: ^1.3.7
  qr_flutter: ^4.1.0
  mobile_scanner: ^5.2.3
  image_picker: ^1.1.2
  cached_network_image: ^3.4.1
  geolocator: ^13.0.1
  table_calendar: ^3.1.2
  jwt_decoder: ^2.0.1
  permission_handler: ^11.3.1
```

### 3.2 Run
```bash
cd cricket_hub
flutter pub get
```

### 3.3 Copy lib/ files
From the unzipped `cricket_hub_phase3/`, copy these to your project:

```
cricket_hub_phase3/lib/core/app_constants.dart          → cricket_hub/lib/core/app_constants.dart  (merge with existing)
cricket_hub_phase3/lib/models/ground_model.dart        → cricket_hub/lib/models/ground_model.dart
cricket_hub_phase3/lib/models/booking_model.dart       → cricket_hub/lib/models/booking_model.dart
cricket_hub_phase3/lib/models/umpire_model.dart        → cricket_hub/lib/models/umpire_model.dart
cricket_hub_phase3/lib/services/ground_service.dart    → cricket_hub/lib/services/ground_service.dart
cricket_hub_phase3/lib/services/booking_service.dart   → cricket_hub/lib/services/booking_service.dart
cricket_hub_phase3/lib/services/payment_service.dart   → cricket_hub/lib/services/payment_service.dart
cricket_hub_phase3/lib/services/umpire_service.dart    → cricket_hub/lib/services/umpire_service.dart
cricket_hub_phase3/lib/screens/ground/                → cricket_hub/lib/screens/ground/  (entire folder)
cricket_hub_phase3/lib/screens/booking/                → cricket_hub/lib/screens/booking/  (entire folder)
```

### 3.4 Edit `lib/main.dart` — add providers
Inside `MultiProvider` providers, add:
```dart
Provider<GroundService>(create: (_) => GroundService()),
Provider<BookingService>(create: (_) => BookingService()),
Provider<PaymentService>(create: (_) => PaymentService()),
Provider<UmpireService>(create: (_) => UmpireService()),
```

### 3.5 Edit `lib/main.dart` — add routes
Inside `routes:` map:
```dart
GroundListScreen.route: (ctx) {
  final args = ModalRoute.of(ctx)?.settings.arguments;
  return GroundListScreen(city: args as String?);
},
GroundDetailScreen.route: (_) => const GroundDetailScreen(),
BookingCheckoutScreen.route: (_) => const BookingCheckoutScreen(),
BookingSuccessScreen.route: (_) => const BookingSuccessScreen(),
```

Add imports at top of `main.dart`:
```dart
import 'screens/ground/ground_list_screen.dart';
import 'screens/ground/ground_detail_screen.dart';
import 'screens/booking/booking_checkout_screen.dart';
import 'screens/booking/booking_success_screen.dart';
```

### 3.6 Edit `lib/screens/menu/menu_screen.dart`
Find the "Ground booking" `_ComingSoonTile` and replace with:
```dart
ListTile(
  leading: Container(
    width: 40, height: 40,
    decoration: BoxDecoration(
      color: AppTheme.surfaceSoft,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.grass_rounded, size: 20, color: AppTheme.textSecondary),
  ),
  title: const Text('Ground booking'),
  subtitle: const Text('Find a place for your next game'),
  trailing: const Icon(Icons.chevron_right_rounded, size: 17),
  onTap: () => Navigator.pushNamed(context, GroundListScreen.route),
),
```

---

## Step 4: Firebase Secrets (4 secrets)

Open a terminal in `cricket_hub/` and run:

```bash
# 4.1 Set Razorpay Key ID (from Step 1.2)
firebase functions:secrets:set RAZORPAY_KEY_ID
# Paste: rzp_test_xxxxxxxxxxxxx

# 4.2 Set Razorpay Key Secret (from Step 1.2)
firebase functions:secrets:set RAZORPAY_KEY_SECRET
# Paste: xxxxxxxxxxxxxxxxxxxxxxxx

# 4.3 Set Razorpay Webhook Secret (from Step 1.3)
firebase functions:secrets:set RAZORPAY_WEBHOOK_SECRET
# Paste: whsec_xxxxxxxxxxxxxx

# 4.4 Set QR JWT Secret (from Step 1.4)
firebase functions:secrets:set QR_JWT_SECRET
# Paste: <your random hex string from Step 1.4>
```

> **Note:** If you see "billing account required" error, first do **Step 7** (enable Blaze plan), then come back.

---

## Step 5: Update Firestore rules + indexes

### 5.1 Update `cricket_hub/firestore.rules`
Open the file. Follow instructions in `cricket_hub_phase3/docs/firestore_rules_phase3_addendum.md`:
1. Append `match /favorite_grounds/{groundId}` and `match /bookings/{bookingId}` inside `match /users/{userId}` block.
2. Append `isVerifiedGround()` and `isVerifiedUmpire()` helper definitions at top.
3. Append all Phase 3 `match /grounds/...`, `match /bookings/...`, `match /umpires/...` etc. blocks at the end.

OR (faster) — replace your entire `firestore.rules` with the version from the addendum (it contains Phase 1+2+3 in one file).

### 5.2 Update `cricket_hub/firestore.indexes.json`
Open the file. Append each index from `cricket_hub_phase3/docs/firestore_indexes_phase3_addendum.json#indexes_to_append[]` to its `indexes` array.

### 5.3 Deploy
```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Expected output:
```
✔ firestore: released rules
✔ firestore: deployed indexes in 20s
```

---

## Step 6: Deploy Cloud Functions

### 6.1 Merge `functions/index.js`
Phase 2 already has `cricket_hub/functions/index.js`. Open it AND `cricket_hub_phase3/functions/index.js`. **Append** Phase 3 exports (the bottom 90% of the Phase 3 file) to Phase 2's file.

> **Watch out:** If you see `function requireUid` or `function isoDate` defined in both files, **remove the duplicate from Phase 3** (keep Phase 2's version).

### 6.2 Update `functions/package.json`
Add to `dependencies`:
```json
{
  "razorpay": "^2.9.5",
  "jsonwebtoken": "^9.0.2",
  "uuid": "^10.0.0"
}
```

### 6.3 Copy tests
```bash
cp cricket_hub_phase3/functions/test/*.js cricket_hub/functions/test/
```

### 6.4 Install + test
```bash
cd cricket_hub/functions
npm install
npm test    # should pass 19/19
```

### 6.5 Deploy
```bash
firebase deploy --only functions
```

Expected output:
```
✔ functions: Finished deploying all functions.
i functions: [createBookingHold] us-central1-[createBookingHold] deployed successfully.
i functions: [createRazorpayOrder] us-central1-[createRazorpayOrder] deployed successfully.
i functions: [verifyRazorpayPayment] us-central1-[verifyRazorpayPayment] deployed successfully.
i functions: [razorpayWebhook] us-central1-[razorpayWebhook] deployed successfully.
... (10 functions total)
```

---

## Step 7: Enable Firebase Blaze Plan (REQUIRED for Cloud Functions + Secrets)

> **Without this, deploy will fail with "billing account required" error.**

1. Go to: https://console.firebase.google.com/project/crickethub-dev/usage
2. Click "Modify plan" → Select **Blaze** (pay-as-you-go)
3. Add billing account (credit/debit card)
4. Set a **budget alert** of ₹2,000 (so you don't get surprised)
5. Click "Purchase"

**Don't worry:** Blaze plan has a **generous free tier** — your Phase 3 prototype won't cost anything if usage stays under:
- Cloud Functions: 2M invocations/month free
- Firestore: 1GB storage + 50K reads/day free
- Razorpay: only charges per transaction (you receive the money first, then 2% fee)

For a prototype with <100 bookings/month, total cost is **<₹500/month** (just Razorpay's 2% transaction fee).

---

## Step 8: Configure Razorpay Webhook URL

1. Go to: https://dashboard.razorpay.com/app/webhooks
2. Find the webhook you created in Step 1.3
3. Edit → Webhook URL field → paste:
   ```
   https://asia-south1-crickethub-dev.cloudfunctions.net/razorpayWebhook
   ```
   (replace `crickethub-dev` with your actual project ID)
4. Save

> **Test it:** Use https://webhook.site/ temporarily if you want to inspect payload shape.

---

## Step 9: End-to-end test

### 9.1 Start emulator (optional, for offline testing)
```bash
cd cricket_hub
firebase emulators:start --only auth,firestore,functions
flutter run
```

### 9.2 Create a test ground (manual in Firestore Console)
1. Go to: https://console.firebase.google.com/project/crickethub-dev/firestore
2. Start a collection: `grounds`
3. Document ID: auto
4. Add fields:
```json
{
  "name": "Test Ground",
  "owner_uid": "YOUR_UID_FROM_AUTH",
  "city": "Ahmedabad",
  "address": "Test Address",
  "lat": 23.0,
  "lng": 72.5,
  "pitch_type": "turf",
  "amenities": ["floodlights", "parking"],
  "photos": [],
  "cover_photo_url": "",
  "price_weekday_hourly": 500,
  "price_weekend_hourly": 800,
  "price_full_day": 0,
  "open_time": "06:00",
  "close_time": "22:00",
  "slot_duration_minutes": 120,
  "status": "active",
  "verified": true,
  "avg_rating": 0.0,
  "review_count": 0,
  "booking_count": 0,
  "ground_stats": {},
  "created_at": <server timestamp>
}
```
5. **Important:** Set `verified: true` so it shows in the public list. In production, this is done by admin.

### 9.3 Run booking flow on device
1. Open app → Menu → "Ground booking"
2. Verify ground appears in list
3. Tap ground → see details
4. Tap "Book this ground" → goes to checkout
5. Select "Online" → "Pay & Book"
6. Razorpay checkout opens in test mode
7. Use test card: `4111 1111 1111 1111`, any future expiry, any CVV
8. Payment success → Booking Success screen with QR code appears
9. Check Firestore → `bookings` collection should have your booking
10. Check `grounds/{id}/slots/{date}` → slot should be `booked` status

---

## 🔍 Troubleshooting

### "Billing account required" on Firebase deploy
→ Complete Step 7 (Blaze plan).

### "Permission denied" on Firestore read
→ Check `firestore.rules` was deployed correctly:
```bash
firebase firestore:rules:get
```

### Razorpay checkout doesn't open
→ Check you set `RAZORPAY_KEY_ID` correctly:
```bash
firebase functions:secrets:access RAZORPAY_KEY_ID
```

### Slot shows "blocked" or doesn't appear
→ Manually create `grounds/{id}/slots/{dateIso}` doc in Firestore with empty `slots` map. The function will fill it on first read.

### Webhook signature fails
→ Verify the webhook secret matches between Razorpay dashboard and `RAZORPAY_WEBHOOK_SECRET`:
```bash
firebase functions:secrets:access RAZORPAY_WEBHOOK_SECRET
```

### "Module not found" on `flutter run`
→ You forgot to add packages to `pubspec.yaml`. See Step 3.1.

### Cloud Function deploy fails with "duplicate function"
→ You forgot to remove duplicate helpers when merging `index.js`. Check `requireUid`, `isoDate`, `parseTimeToMinutes`, `minutesToTime`, `generateSlotsForGround`, `sendTopicNotification`.

---

## 📋 Final verification checklist

After completing all 9 steps, run this verification:

```bash
# 1. Verify Firebase secrets
firebase functions:secrets:list
# Should show: RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET, RAZORPAY_WEBHOOK_SECRET, QR_JWT_SECRET

# 2. Verify Cloud Functions deployed
firebase functions:list
# Should show 10+ functions including createBookingHold, createRazorpayOrder, etc.

# 3. Verify Firestore rules
firebase firestore:rules:get | grep -c "match /grounds"
# Should return >= 1

# 4. Verify Firestore indexes
firebase firestore:indexes
# Should show 8+ composite indexes

# 5. Run unit tests
cd cricket_hub/functions && npm test
# Should pass 19/19

# 6. Run Flutter analyze
cd .. && flutter analyze
# Should show 0 errors (warnings OK)

# 7. End-to-end booking
# Run app, book a test ground with test card 4111...
# Verify booking appears in Firestore + slot is booked
```

When all 7 pass, **Phase 3 is complete and ready for production** 🎉

---

**Total estimated time: 70 minutes (1-2 hours)** ⏱️

Most of it is just **copy-paste + Firebase console clicks**. The hard part (writing the code) is already done by me. 🚀