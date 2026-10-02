import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_constants.dart';
import '../models/ground_model.dart';
import '../models/umpire_model.dart';

/// All umpire-related Firestore calls live here.
/// Matches CricketHub_Backend_Schema_Phase3.md -> Collection: umpires.
class UmpireService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _umpires =>
      _db.collection(AppConstants.umpiresCol);

  Stream<List<Umpire>> umpiresByCityStream(String city, {int limit = 50}) {
    return _umpires
        .where('city', isEqualTo: city)
        .where('status', isEqualTo: 'active')
        .where('verified', isEqualTo: true)
        .orderBy('avg_rating', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Umpire.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Future<Umpire?> getUmpire(String uid) async {
    final snap = await _umpires.doc(uid).get();
    if (!snap.exists) return null;
    return Umpire.fromFirestore(uid, snap.data()!);
  }

  Stream<Umpire?> umpireStream(String uid) {
    return _umpires.doc(uid).snapshots().map(
          (snap) =>
              snap.exists ? Umpire.fromFirestore(uid, snap.data()!) : null,
        );
  }

  Future<void> registerUmpire(Umpire umpire) async {
    await _umpires.doc(umpire.uid).set(umpire.toCreateMap());
  }

  Future<void> updateUmpire(String uid, Map<String, dynamic> updates) async {
    await _umpires.doc(uid).update({
      ...updates,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitForVerification(String uid) async {
    await _umpires.doc(uid).update({
      'status': 'pending_verification',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Umpire per-day availability inventory — same shape as ground slots.
  Stream<GroundSlotDay> availabilityStream(String umpireUid, String dateIso) {
    return _umpires
        .doc(umpireUid)
        .collection(AppConstants.umpireAvailabilitySubCol)
        .doc(dateIso)
        .snapshots()
        .map((snap) => GroundSlotDay.fromFirestore(dateIso, snap.data()));
  }
}