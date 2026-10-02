import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_constants.dart';
import '../models/ground_model.dart';

/// All ground-related Firestore calls live here.
/// Matches CricketHub_Backend_Schema_Phase3.md -> Collection: grounds.
class GroundService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _grounds =>
      _db.collection(AppConstants.groundsCol);

  /// Stream of all active, verified grounds in [city].
  Stream<List<Ground>> groundsByCityStream(String city) {
    return _grounds
        .where('city', isEqualTo: city)
        .where('status', isEqualTo: 'active')
        .where('verified', isEqualTo: true)
        .orderBy('avg_rating', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Ground.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Filtered search. Pass any combination of pitchType, maxPrice, amenities.
  Stream<List<Ground>> searchGrounds({
    required String city,
    String? pitchType,
    int? maxPrice,
    List<String>? amenities,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query = _grounds
        .where('city', isEqualTo: city)
        .where('status', isEqualTo: 'active')
        .where('verified', isEqualTo: true)
        .orderBy('avg_rating', descending: true)
        .limit(limit);

    if (pitchType != null && pitchType.isNotEmpty) {
      query = query.where('pitch_type', isEqualTo: pitchType);
    }
    if (maxPrice != null) {
      query = query.where('price_weekday_hourly', isLessThanOrEqualTo: maxPrice);
    }

    return query.snapshots().map((snap) {
      Iterable<Ground> list = snap.docs.map(
        (doc) => Ground.fromFirestore(doc.id, doc.data()),
      );
      // Amenities filter must run client-side because Firestore array-contains
      // supports only a single value per query.
      if (amenities != null && amenities.isNotEmpty) {
        list = list.where((g) => amenities.every(g.amenities.contains));
      }
      return list.toList();
    });
  }

  Future<Ground?> getGround(String groundId) async {
    final snap = await _grounds.doc(groundId).get();
    if (!snap.exists) return null;
    return Ground.fromFirestore(snap.id, snap.data()!);
  }

  Stream<Ground?> groundStream(String groundId) {
    return _grounds.doc(groundId).snapshots().map(
          (snap) =>
              snap.exists ? Ground.fromFirestore(snap.id, snap.data()!) : null,
        );
  }

  /// All grounds owned by [uid] (any status).
  Stream<List<Ground>> ownerGroundsStream(String uid) {
    return _grounds
        .where('owner_uid', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Ground.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Future<String> createGround(Ground ground) async {
    final doc = await _grounds.add(ground.toCreateMap());
    return doc.id;
  }

  Future<void> updateGround(String groundId, Map<String, dynamic> updates) async {
    await _grounds.doc(groundId).update({
      ...updates,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitForVerification(String groundId) async {
    await _grounds.doc(groundId).update({
      'status': 'pending_verification',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Stream of slot inventory for a single [dateIso] (e.g., '2025-04-15').
  Stream<GroundSlotDay> daySlotsStream(String groundId, String dateIso) {
    return _grounds
        .doc(groundId)
        .collection(AppConstants.slotsSubCol)
        .doc(dateIso)
        .snapshots()
        .map((snap) => GroundSlotDay.fromFirestore(dateIso, snap.data()));
  }

  Future<GroundSlotDay?> getDaySlots(String groundId, String dateIso) async {
    final snap = await _grounds
        .doc(groundId)
        .collection(AppConstants.slotsSubCol)
        .doc(dateIso)
        .get();
    if (!snap.exists) return null;
    return GroundSlotDay.fromFirestore(dateIso, snap.data());
  }

  /// Owner-only: write a whole-day block.
  Future<void> blockDay(String groundId, String dateIso, {String? reason}) async {
    await _grounds
        .doc(groundId)
        .collection(AppConstants.slotsSubCol)
        .doc(dateIso)
        .set(
      {
        'date': dateIso,
        'blocked': true,
        if (reason != null) 'block_reason': reason,
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> unblockDay(String groundId, String dateIso) async {
    await _grounds
        .doc(groundId)
        .collection(AppConstants.slotsSubCol)
        .doc(dateIso)
        .set(
      {
        'date': dateIso,
        'blocked': false,
        'block_reason': FieldValue.delete(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // Favorites (Phase 3 — sub-collection under users/{uid})
  Future<void> favoriteGround(String uid, String groundId) async {
    await _db
        .collection(AppConstants.usersCol)
        .doc(uid)
        .collection(AppConstants.favoriteGroundsSubCol)
        .doc(groundId)
        .set({'ground_id': groundId, 'saved_at': FieldValue.serverTimestamp()});
  }

  Future<void> unfavoriteGround(String uid, String groundId) async {
    await _db
        .collection(AppConstants.usersCol)
        .doc(uid)
        .collection(AppConstants.favoriteGroundsSubCol)
        .doc(groundId)
        .delete();
  }

  Stream<bool> isFavoritedStream(String uid, String groundId) {
    return _db
        .collection(AppConstants.usersCol)
        .doc(uid)
        .collection(AppConstants.favoriteGroundsSubCol)
        .doc(groundId)
        .snapshots()
        .map((snap) => snap.exists);
  }
}